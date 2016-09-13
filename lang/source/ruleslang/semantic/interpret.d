module ruleslang.semantic.interpret;

import std.format : format;

import ruleslang.syntax.source;
import ruleslang.syntax.token;
import ruleslang.syntax.ast.type;
import ruleslang.syntax.ast.expression;
import ruleslang.semantic.tree;
import ruleslang.semantic.context;
import ruleslang.semantic.type;
import ruleslang.semantic.symbol;
import ruleslang.util;

public immutable class Interpreter {
    public static immutable Interpreter INSTANCE = new immutable Interpreter();

    private this() {
    }

    public immutable(Type) interpretNamedType(Context context, NamedTypeAst namedType) {
        auto name = namedType.name;
        if (name.length != 1) {
            throw new SourceException("Multi-part type names are not supported right now", namedType);
        }
        // Get the type from the name by doing a context lookup
        auto nameSource = name[0].getSource();
        string exceptionMessage;
        auto type = collectExceptionMessage(context.resolveType(nameSource), exceptionMessage);
        if (exceptionMessage !is null) {
            throw new SourceException(exceptionMessage, name[0]);
        }
        if (type is null) {
            throw new SourceException(format("No type for name %s", nameSource), name[0]);
        }
        // Add array dimensions if any
        immutable(Type)* wrapped = &type;
        foreach (dimension; namedType.dimensions) {
            if (dimension is null) {
                // Null means unsized
                immutable(Type) unsized = new immutable ArrayType(*wrapped);
                wrapped = &unsized;
            } else {
                // Check if the size has type uint64
                auto sizeNodeType = dimension.interpret(context).reduceLiterals().getType();
                auto conversions = new TypeConversionChain();
                if (!sizeNodeType.specializableTo(AtomicType.UINT64, conversions)) {
                    throw new SourceException(format("Size type %s is not convertible to uint64", sizeNodeType.toString()),
                            dimension);
                }
                // Try to get the size (should be available as a literal)
                auto literalSizeNodeType = cast(immutable IntegerLiteralType) sizeNodeType;
                if (literalSizeNodeType is null) {
                    throw new SourceException("Array size must be known at compile time", dimension);
                }
                auto size = literalSizeNodeType.unsignedValue();
                immutable(Type) sized = new immutable SizedArrayType(*wrapped, size);
                wrapped = &sized;
            }
        }
        return *wrapped;
    }

    public immutable(AnyType) interpretAnyType(Context context, AnyTypeAst namedType) {
        return AnyType.INSTANCE;
    }

    public immutable(TupleType) interpretTupleType(Context context, TupleTypeAst namedType) {
        assert (0);
    }

    public immutable(StructureType) interpretStructType(Context context, StructTypeAst namedType) {
        assert (0);
    }

    public immutable(NullLiteralNode) interpretNullLiteral(Context context, NullLiteral nullLiteral) {
        return new immutable NullLiteralNode(nullLiteral.start, nullLiteral.end);
    }

    public immutable(BooleanLiteralNode) interpretBooleanLiteral(Context context, BooleanLiteral boolean) {
        return new immutable BooleanLiteralNode(boolean.getValue(), boolean.start, boolean.end);
    }

    public immutable(StringLiteralNode) interpretStringLiteral(Context context, StringLiteral _string) {
        return new immutable StringLiteralNode(_string.getValue(), _string.start, _string.end);
    }

    public immutable(UnsignedIntegerLiteralNode) interpretCharacterLiteral(Context context,
            CharacterLiteral character) {
        return new immutable UnsignedIntegerLiteralNode(cast(ulong) character.getValue(),
                character.start, character.end);
    }

    public immutable(SignedIntegerLiteralNode) interpretSignedIntegerLiteral(Context context,
            SignedIntegerLiteral integer) {
        bool overflow;
        auto value = integer.getValue(false, overflow);
        if (overflow) {
            throw new SourceException("Signed integer overflow", integer);
        }
        return new immutable SignedIntegerLiteralNode(value, integer.start, integer.end);
    }

    public immutable(UnsignedIntegerLiteralNode) interpretUnsignedIntegerLiteral(Context context,
            UnsignedIntegerLiteral integer) {
        bool overflow;
        auto value = integer.getValue(overflow);
        if (overflow) {
            throw new SourceException("Unsigned integer overflow", integer);
        }
        return new immutable UnsignedIntegerLiteralNode(value, integer.start, integer.end);
    }

    public immutable(FloatLiteralNode) interpretFloatLiteral(Context context, FloatLiteral floating) {
        bool overflow;
        auto value = floating.getValue(overflow);
        if (overflow) {
            throw new SourceException("Floating point overflow/underflow", floating);
        }
        return new immutable FloatLiteralNode(value, floating.start, floating.end);
    }

    public immutable(TypedNode) interpretNameReference(Context context, NameReference nameReference) {
        auto name = nameReference.name;
        // The first name is always that of a field
        auto firstPart = name[0];
        auto field = context.resolveField(firstPart.getSource());
        if (field is null) {
            throw new SourceException(format("No field found for name %s", firstPart.getSource()), firstPart);
        }
        immutable(TypedNode) fieldAccess = new immutable FieldAccessNode(field, firstPart.start, firstPart.end);
        // If the name has more parts, treat the next as a structure member accesses
        immutable(TypedNode)* lastAccess = &fieldAccess;
        foreach (i, part; name[1 .. $]) {
            immutable(TypedNode) memberAccess = interpretMemberAccess(new NameReference(name[0 .. i + 1]), *lastAccess, part);
            lastAccess = &memberAccess;
        }
        return *lastAccess;
    }

    public immutable(TypedNode) interpretCompositeLiteral(Context context, CompositeLiteral compositeLiteral) {
        auto values = compositeLiteral.values;
        if (values.length == 0) {
            // This is the any type. It has no members
            return new immutable EmptyLiteralNode(compositeLiteral.start, compositeLiteral.end);
        }
        // Determine the type from the first label
        // Un-labeled is tuple, integer labeled is array and identifier labeled is struct
        auto label = values[0].label;
        if (label is null) {
            return interpretTupleLiteral(context, compositeLiteral);
        }
        switch (label.getKind()) with (Kind) {
            case IDENTIFIER:
                return interpretStructLiteral(context, compositeLiteral);
            case SIGNED_INTEGER_LITERAL:
            case UNSIGNED_INTEGER_LITERAL:
                return interpretArrayLiteral(context, compositeLiteral);
            default:
                throw new SourceException(format("Unsupported label type %s", label.getKind().toString()), label);
        }
    }

    private static immutable(TypedNode) interpretTupleLiteral(Context context, CompositeLiteral compositeLiteral) {
        immutable(TypedNode)[] valueNodes = [];
        foreach (LabeledExpression value; compositeLiteral.values) {
            valueNodes ~= value.expression.interpret(context).reduceLiterals();
            auto label = value.label;
            // Tuples are un-labeled
            if (label !is null) {
                throw new SourceException("Did not expect a label since the other members are not labeled", label);
            }
        }
        return new immutable TupleLiteralNode(valueNodes, compositeLiteral.start, compositeLiteral.end);
    }

    private static immutable(TypedNode) interpretStructLiteral(Context context, CompositeLiteral compositeLiteral) {
        immutable(TypedNode)[] valueNodes = [];
        immutable(StructLabel)[] labels;
        foreach (LabeledExpression value; compositeLiteral.values) {
            valueNodes ~= value.expression.interpret(context).reduceLiterals();
            auto label = value.label;
            // Structs only have identifier labels
            if (label is null) {
                throw new SourceException("Expected a label on the expression", value.expression);
            }
            if (label.getKind() != Kind.IDENTIFIER) {
                throw new SourceException("Struct label must be an identifier", label);
            }
            labels ~= immutable StructLabel(label.getSource(), label.start, label.end);
        }
        return new immutable StructLiteralNode(valueNodes, labels, compositeLiteral.start, compositeLiteral.end);
    }

    private static immutable(TypedNode) interpretArrayLiteral(Context context, CompositeLiteral compositeLiteral) {
        immutable(TypedNode)[] valueNodes = [];
        immutable(ArrayLabel)[] labels = [];
        foreach (LabeledExpression value; compositeLiteral.values) {
            valueNodes ~= value.expression.interpret(context).reduceLiterals();
            labels ~= checkArrayLabel(value);
        }
        return new immutable ArrayLiteralNode(valueNodes, labels, compositeLiteral.start, compositeLiteral.end);
    }

    private static immutable(ArrayLabel) checkArrayLabel(LabeledExpression labeledExpression) {
        // A label must be present
        auto label = labeledExpression.label;
        if (label is null) {
            throw new SourceException("Expected a label on the expression", labeledExpression.expression);
        }
        // It can be a signed integer, as long as it is positive
        auto signedIntegerLabel = cast(SignedIntegerLiteral) label;
        if (signedIntegerLabel !is null) {
            bool overflow;
            long index = signedIntegerLabel.getValue(false, overflow);
            if (overflow) {
                throw new SourceException("Signed integer overflow", signedIntegerLabel);
            }
            if (index < 0) {
                throw new SourceException("Index cannot be negative", signedIntegerLabel);
            }
            return immutable ArrayLabel(cast(ulong) index, signedIntegerLabel.start, signedIntegerLabel.end);
        }
        // It can be an unsigned integer
        auto unsignedIntegerLabel = cast(UnsignedIntegerLiteral) label;
        if (unsignedIntegerLabel !is null) {
            bool overflow;
            ulong index = unsignedIntegerLabel.getValue(overflow);
            if (overflow) {
                throw new SourceException("Unsigned integer overflow", unsignedIntegerLabel);
            }
            return immutable ArrayLabel(index, unsignedIntegerLabel.start, unsignedIntegerLabel.end);
        }
        // It can be the identifier "other"
        auto identifierLabel = cast(Identifier) label;
        if (identifierLabel !is null) {
            if (identifierLabel.getSource() != "other") {
                throw new SourceException("The only valid identifier for an array label is \"other\"", identifierLabel);
            }
            return ArrayLabel.asOther(identifierLabel.start, identifierLabel.end);
        }
        throw new SourceException(format("Not a valid array label %s", label.getSource()), label);
    }

    public immutable(TypedNode) interpretInitializer(Context context, Initializer expression) {
        return NullNode.INSTANCE;
    }

    public immutable(TypedNode) interpretContextMemberAccess(Context context, ContextMemberAccess expression) {
        return NullNode.INSTANCE;
    }

    public immutable(MemberAccessNode) interpretMemberAccess(Context context, MemberAccess memberAccess) {
        auto valueNode = memberAccess.value.interpret(context).reduceLiterals();
        return interpretMemberAccess(memberAccess.value, valueNode, memberAccess.name);
    }

    private static immutable(MemberAccessNode) interpretMemberAccess(Expression value, immutable(TypedNode) valueNode,
            Identifier name) {
        auto structureType = cast(immutable StructureType) valueNode.getType();
        if (structureType is null) {
            throw new SourceException(format("Type %s has no members", valueNode.getType()), value);
        }
        auto memberName = name.getSource();
        auto memberType = structureType.getMemberType(memberName);
        if (memberType is null) {
            throw new SourceException(format("No member named %s in type %s", memberName, structureType.toString()), name);
        }
        return new immutable MemberAccessNode(valueNode, memberName, name.start, name.end);
    }

    public immutable(TypedNode) interpretIndexAccess(Context context, IndexAccess indexAccess) {
        // Interpret both the value and the index
        auto valueNode = indexAccess.value.interpret(context).reduceLiterals();
        auto indexNode = indexAccess.index.interpret(context).reduceLiterals();
        // Check if the value type is a indexible
        auto valueType = valueNode.getType();
        auto referenceType = cast(immutable ReferenceType) valueType;
        if (referenceType is null) {
            throw new SourceException(format("Not a composite type %s", valueType.toString()), indexAccess.value);
        }
        // Check if the index type is uint64
        auto indexType = indexNode.getType();
        auto conversions = new TypeConversionChain();
        if (!indexType.specializableTo(AtomicType.UINT64, conversions)) {
            throw new SourceException(format("Index type %s is not convertible to uint64", indexType.toString()),
                    indexAccess.index);
        }
        // Attempt to create the node. This can fail if the index is out of range (determined through literal types)
        return new immutable IndexAccessNode(valueNode, indexNode, indexAccess.start, indexAccess.end);
    }

    public immutable(TypedNode) interpretFunctionCall(Context context, FunctionCall call) {
        // Figure out if the call value is the name of a function or an actual value
        auto value = call.value;
        auto nameReference = cast(NameReference) value;
        if (nameReference is null) {
            // If the value isn't a name reference, we might have a member access
            // Either the accessed member is a function type or UFCS is being used
            auto memberAccess = cast(MemberAccess) value;
            if (memberAccess is null) {
                // No member, this is just a value call (no function name is given)
                return interpretValueCall(value, value.interpret(context).reduceLiterals());
            }
            // Otherwise the value is being called with the member name as the function name
            auto lastName = memberAccess.name;
            auto memberValue = memberAccess.value;
            return interpretValueFunctionCall(context, call, memberValue, lastName);
        }
        // We treat simple and multi-part name references separately
        auto name = nameReference.name;
        if (name.length == 1) {
            // Simple name references require disambiguation between field and functions
            return interpretSimpleFunctionCall(context, call, nameReference);
        }
        // Multi-part name references require disambiguation between members and functions
        auto firstPart = new NameReference(name[0 .. $ - 1]);
        return interpretValueFunctionCall(context, call, firstPart, name[$ - 1]);
    }

    private static immutable(TypedNode) interpretSimpleFunctionCall(Context context, FunctionCall call,
            NameReference nameReference) {
        auto argumentNodes = interpretArgumentNodes(context, call);
        auto argumentTypes = argumentNodes.getTypes();
        // If the value is a single part name, then it is either a field or a function
        assert (nameReference.name.length == 1);
        auto name = nameReference.name[0];
        auto nameSource = name.getSource();
        auto field = context.resolveField(nameSource);
        auto func = resolveFunction(context, call, name, argumentTypes);
        // It should not resolve to both a field and a function
        if (field !is null && func !is null) {
            throw new SourceException(format("Found a field and a function for the name %s", nameSource), nameReference);
        }
        // Treat a field like a value
        if (field !is null) {
            auto valueCallNode = new immutable FieldAccessNode(field, name.start, name.end);
            return interpretValueCall(nameReference, valueCallNode);
        }
        // Otherwise use the function
        if (func is null) {
            functionNotFound(call, name, argumentTypes);
        }
        return new immutable FunctionCallNode(func, argumentNodes, call.start, call.end);
    }

    private static immutable(TypedNode) interpretValueFunctionCall(Context context, FunctionCall call, Expression value,
            Identifier name) {
        auto valueNode = value.interpret(context).reduceLiterals();
        // If the value is a multi-part name, then all but the last part should
        // resolve to some value. The last name is either a structure member or
        // the name of a function (when using UFCS). The member has priority
        auto structureType = cast(immutable StructureType) valueNode.getType();
        if (structureType !is null) {
            // If the name points to a structure, check if the last part is a member
            auto nameSource = name.getSource();
            auto memberType = structureType.getMemberType(nameSource);
            if (memberType !is null) {
                auto valueCallNode = new immutable MemberAccessNode(valueNode, nameSource, name.start, name.end);
                return interpretValueCall(value, valueCallNode);
            }
        }
        // Otherwise apply the UFCS transformation: the last part becomes the function name
        // and value of the previous parts become the first argument of the call
        // Example: a.b.c(d, e) -> c(a.b, d, e)
        auto argumentNodes = valueNode ~ interpretArgumentNodes(context, call);
        auto argumentTypes = argumentNodes.getTypes();
        auto func = resolveFunction(context, call, name, argumentTypes);
        if (func is null) {
            functionNotFound(call, name, argumentTypes);
        }
        return new immutable FunctionCallNode(func, argumentNodes, call.start, call.end);
    }

    private static immutable(TypedNode) interpretValueCall(Expression value, immutable(TypedNode) valueNode) {
        /*
            TODO: when function type are added, check if value is one and call it, instead of doing UFCS immediately
            auto functionType = cast(immutable FunctionType) valueNode.getType();
            if (functionType is null) {
                throw new SourceException(format("Type %s is not callable", valueNode.getType()), value);
            }
            if (!functionType.isApplicable(argumentNodes)) {
                throw new SourceException(format("Type %s is not callable with %s",
                        valueNode.getType(), argumentTypes.join!", "()), value.start, end);
            }
            return new immutable ValueCallNode(valueNode, argumentNodes);
        */
        throw new SourceException(format("Type %s is not callable", valueNode.getType()), value);
    }

    private static immutable(Function) resolveFunction(Context context, FunctionCall call, Identifier name,
            immutable(Type)[] argumentTypes) {
        string exceptionMessage;
        auto func = collectExceptionMessage(context.resolveFunction(name.getSource(), argumentTypes), exceptionMessage);
        if (exceptionMessage !is null) {
            throw new SourceException(exceptionMessage, call);
        }
        return func;
    }

    private static immutable(FunctionCallNode) functionNotFound(FunctionCall call, Identifier name,
            immutable(Type)[] argumentTypes) {
        throw new SourceException(format("No function found for call %s(%s)", name.getSource(), argumentTypes.join!", "()),
                call.start, call.end);
    }

    private static immutable(TypedNode)[] interpretArgumentNodes(Context context, FunctionCall call) {
        immutable(TypedNode)[] argumentNodes;
        argumentNodes.reserve(call.arguments.length);
        foreach (argument; call.arguments) {
            argumentNodes ~= argument.interpret(context).reduceLiterals();
        }
        return argumentNodes;
    }

    public immutable(TypedNode) interpretSign(Context context, Sign sign) {
        auto integer = cast(SignedIntegerLiteral) sign.inner;
        if (integer && integer.radix == 10) {
            bool overflow;
            auto value = integer.getValue(sign.operator == "-", overflow);
            if (overflow) {
                throw new SourceException("Signed integer overflow", sign);
            }
            return new immutable SignedIntegerLiteralNode(value, integer.start, integer.end);
        }
        assert (0);
    }

    public immutable(TypedNode) interpretLogicalNot(Context context, LogicalNot expression) {
        assert (0);
    }

    public immutable(TypedNode) interpretBitwiseNot(Context context, BitwiseNot expression) {
        assert (0);
    }

    public immutable(TypedNode) interpretExponent(Context context, Exponent expression) {
        assert (0);
    }

    public immutable(TypedNode) interpretInfix(Context context, Infix expression) {
        assert (0);
    }

    public immutable(TypedNode) interpretMultiply(Context context, Multiply expression) {
        assert (0);
    }

    public immutable(TypedNode) interpretAdd(Context context, Add expression) {
        assert (0);
    }

    public immutable(TypedNode) interpretShift(Context context, Shift expression) {
        assert (0);
    }

    public immutable(TypedNode) interpretCompare(Context context, Compare expression) {
        assert (0);
    }

    public immutable(TypedNode) interpretValueCompare(Context context, ValueCompare valueCompare) {
        bool negated = false;
        final switch (valueCompare.operator.getSource()) {
            case "!==": {
                negated = true;
                goto case "===";
            }
            case "===": {
                // The left and right types must be reference types or null
                auto leftNode = valueCompare.left.interpret(context).reduceLiterals();
                if (cast(immutable ReferenceType) leftNode.getType() is null
                        && cast(immutable NullType) leftNode.getType() is null) {
                    throw new SourceException(format("Left type must be a reference type or null, not %s",
                            leftNode.getType()), valueCompare.left);
                }
                auto rightNode = valueCompare.right.interpret(context).reduceLiterals();
                if (cast(immutable ReferenceType) rightNode.getType() is null
                        && cast(immutable NullType) rightNode.getType() is null) {
                    throw new SourceException(format("Right type must be a reference type or null, not %s",
                            rightNode.getType()), valueCompare.right);
                }
                return new immutable ReferenceCompareNode(leftNode, rightNode, negated, valueCompare.start, valueCompare.end);
            }
        }
    }

    public immutable(TypedNode) interpretTypeCompare(Context context, TypeCompare typeCompare) {
        // The value must be a reference type
        auto valueNode = typeCompare.value.interpret(context).reduceLiterals();
        if (cast(immutable ReferenceType) valueNode.getType() is null) {
            throw new SourceException(format("Value must be a reference type, not %s", valueNode.getType()), typeCompare.value);
        }
        // Get the comparison kind from the operator
        TypeCompareNode.Kind kind;
        final switch (typeCompare.operator.getSource()) with (TypeCompareNode.Kind) {
            case "::":
                kind = EQUAL;
                break;
            case "!:":
                kind = NOT_EQUAL;
                break;
            case "<:":
                kind = SUBTYPE;
                break;
            case ">:":
                kind = SUPERTYPE;
                break;
            case "<<:":
                kind = PROPER_SUBTYPE;
                break;
            case ">>:":
                kind = PROPER_SUPERTYPE;
                break;
            case "<:>":
                kind = DISTINCT;
                break;
        }
        // Get the type to compare against
        auto type = typeCompare.type.interpret(context);
        auto referenceType = cast(immutable ReferenceType) type;
        if (referenceType is null) {
            throw new SourceException(format("Not a reference type %s", type.toString()), typeCompare.type);
        }
        return new immutable TypeCompareNode(valueNode, referenceType, kind, typeCompare.start, typeCompare.end);
    }

    public immutable(TypedNode) interpretBitwiseAnd(Context context, BitwiseAnd expression) {
        assert (0);
    }

    public immutable(TypedNode) interpretBitwiseXor(Context context, BitwiseXor expression) {
        assert (0);
    }

    public immutable(TypedNode) interpretBitwiseOr(Context context, BitwiseOr expression) {
        assert (0);
    }

    public immutable(TypedNode) interpretLogicalAnd(Context context, LogicalAnd logicalAnd) {
        // Both the left and right nodes must be bools
        auto leftNode = logicalAnd.left.interpret(context).reduceLiterals();
        if (!AtomicType.BOOL.opEquals(leftNode.getType())) {
            throw new SourceException(format("Left type must be bool, not %s", leftNode.getType()), logicalAnd.left);
        }
        auto rightNode = logicalAnd.right.interpret(context).reduceLiterals();
        if (!AtomicType.BOOL.opEquals(rightNode.getType())) {
            throw new SourceException(format("Right type must be bool, not %s", rightNode.getType()), logicalAnd.right);
        }
        // Implement "logical and" as a conditional to support short-circuiting
        auto shortCircuit = new immutable BooleanLiteralNode(false, rightNode.start, rightNode.end);
        return new immutable ConditionalNode(leftNode, rightNode, shortCircuit, logicalAnd.start, logicalAnd.end);
    }

    public immutable(TypedNode) interpretLogicalXor(Context context, LogicalXor expression) {
        assert (0);
    }

    public immutable(TypedNode) interpretLogicalOr(Context context, LogicalOr logicalOr) {
        // Both the left and right nodes must be bools
        auto leftNode = logicalOr.left.interpret(context).reduceLiterals();
        if (!AtomicType.BOOL.opEquals(leftNode.getType())) {
            throw new SourceException(format("Left type must be bool, not %s", leftNode.getType()), logicalOr.left);
        }
        auto rightNode = logicalOr.right.interpret(context).reduceLiterals();
        if (!AtomicType.BOOL.opEquals(rightNode.getType())) {
            throw new SourceException(format("Right type must be bool, not %s", rightNode.getType()), logicalOr.right);
        }
        // Implement "logical or" as a conditional to support short-circuiting
        auto shortCircuit = new immutable BooleanLiteralNode(true, leftNode.start, leftNode.end);
        return new immutable ConditionalNode(leftNode, shortCircuit, rightNode, logicalOr.start, logicalOr.end);
    }

    public immutable(TypedNode) interpretConcatenate(Context context, Concatenate expression) {
        assert (0);
    }

    public immutable(TypedNode) interpretRange(Context context, Range expression) {
        assert (0);
    }

    public immutable(TypedNode) interpretConditional(Context context, Conditional conditional) {
        // Get the condition node and make sure it is a bool type
        auto conditionNode = conditional.condition.interpret(context).reduceLiterals();
        if (!AtomicType.BOOL.opEquals(conditionNode.getType())) {
            throw new SourceException(format("Condition type must be bool, not %s", conditionNode.getType()),
                    conditional.condition);
        }
        // Get the value nodes
        auto trueNode = conditional.trueValue().interpret(context).reduceLiterals();
        auto falseNode = conditional.falseValue().interpret(context).reduceLiterals();
        return new immutable ConditionalNode(conditionNode, trueNode, falseNode, conditional.start, conditional.end);
    }
}
