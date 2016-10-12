module ruleslang.semantic.interpret;

import std.format : format;
import std.typecons : Rebindable;
import std.algorithm.searching : any;

import ruleslang.syntax.source;
import ruleslang.syntax.token;
import ruleslang.syntax.ast.type;
import ruleslang.syntax.ast.expression;
import ruleslang.syntax.ast.statement;
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
        immutable(TypedNode)[] runtimeSizes;
        return interpretNamedType!false(context, namedType, runtimeSizes);
    }

    private static immutable(Type) interpretNamedType(bool allowRuntimeSize)(Context context, NamedTypeAst namedType,
            out immutable(TypedNode)[] runtimeSizes) {
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
        Rebindable!(immutable Type) wrapped = type;
        foreach (dimension; namedType.dimensions) {
            if (dimension is null) {
                // Null means unsized
                wrapped = new immutable ArrayType(wrapped);
                static if (allowRuntimeSize) {
                    // Append null to indicate that the size doesn't matter
                    runtimeSizes ~= null;
                }
            } else {
                // Check if the size has type uint64
                auto sizeNode = dimension.interpret(context).reduceLiterals();
                auto sizeNodeType = sizeNode.getType();
                if (!sizeNodeType.specializableTo(AtomicType.UINT64)) {
                    throw new SourceException(format("Size type %s is not convertible to uint64", sizeNodeType.toString()),
                            dimension);
                }
                // Try to get the size (it might be available as a literal)
                if (auto literalSizeNodeType = cast(immutable IntegerLiteralType) sizeNodeType) {
                    wrapped = new immutable SizedArrayType(wrapped, literalSizeNodeType.unsignedValue());
                    static if (allowRuntimeSize) {
                        // Append null to indicate that the size doesn't matter
                        runtimeSizes ~= null;
                    }
                } else {
                    static if (allowRuntimeSize) {
                        // We can evaluate the size at runtime instead, so we'll use a size of zero temporarily
                        wrapped = new immutable SizedArrayType(wrapped, 0);
                        // Append the size node so we know where to get the size at runtime
                        runtimeSizes ~= sizeNode;
                    } else {
                        throw new SourceException("Array size must be known at compile time", dimension);
                    }
                }
            }
        }
        return wrapped;
    }

    public immutable(AnyType) interpretAnyType(Context context, AnyTypeAst anyType) {
        return AnyType.INSTANCE;
    }

    public immutable(TupleType) interpretTupleType(Context context, TupleTypeAst tupleType) {
        immutable(Type)[] memberTypes;
        foreach (memberType; tupleType.memberTypes) {
            memberTypes ~= memberType.interpret(context);
        }
        return new immutable TupleType(memberTypes);
    }

    public immutable(StructureType) interpretStructType(Context context, StructTypeAst structType) {
        immutable(Type)[] memberTypes;
        immutable(string)[] memberNames;
        foreach (i, memberType; structType.memberTypes) {
            memberTypes ~= memberType.interpret(context);
            memberNames ~= structType.memberNames[i].getSource();
        }
        return new immutable StructureType(memberTypes, memberNames);
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
        Rebindable!(immutable TypedNode) lastAccess = fieldAccess;
        foreach (i, part; name[1 .. $]) {
            immutable(TypedNode) memberAccess = interpretMemberAccess(new NameReference(name[0 .. i + 1]), lastAccess, part);
            lastAccess = memberAccess;
        }
        return lastAccess;
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

    public immutable(TypedNode) interpretInitializer(Context context, Initializer initializer) {
        // Interpret the type, allowing runtime sizes
        immutable(TypedNode)[] runtimeSizes;
        auto type = interpretNamedType!true(context, initializer.type, runtimeSizes);
        // Interpret the composite literal
        auto literalNode = initializer.literal.interpret(context).castOrFail!(immutable LiteralNode);
        // Check if we can initialize the literal as the given type
        auto literalType = literalNode.getType();
        if (!literalType.specializableTo(type)) {
            throw new SourceException(format("Cannot specialize %s to %s", literalType.toString(), type.toString()),
                    initializer);
        }
        // Apply the specialization
        auto specialized = literalNode.specializeTo(type);
        if (specialized is null) {
            throw new SourceException(format("Specialization from %s to %s is not implemented",
                    literalType.toString(), type.toString()), initializer);
        }
        // If we have an array literal then we must add array initializers for runtime-sized arrays
        if (runtimeSizes.any!(a => a !is null)) {
            if (auto arrayLiteral = cast(immutable ArrayLiteralNode) specialized) {
                return addArrayInitializers(arrayLiteral, runtimeSizes);
            }
        }
        return specialized;
    }

    private static immutable(TypedNode) addArrayInitializers(immutable ArrayLiteralNode literal,
            immutable(TypedNode)[] runtimeSizes, size_t depth = 0) {
        // Check that we're not recursing past the array depth
        if (depth >= runtimeSizes.length) {
            return literal;
        }
        // Wrapped recursively all array literals in this literal
        immutable(TypedNode)[] wrappedValues;
        foreach (value; literal.values) {
            if (auto nestedLiteral = cast(immutable ArrayLiteralNode) value) {
                wrappedValues ~= addArrayInitializers(nestedLiteral, runtimeSizes, depth + 1);
            } else {
                wrappedValues ~= value;
            }
        }
        auto wrapped = new immutable ArrayLiteralNode(wrappedValues, literal.labels, literal.start, literal.end);
        // If the arrays has a runtime size then we wrap it in an array initializer
        if (auto size = runtimeSizes[runtimeSizes.length - 1 - depth]) {
            return new immutable ArrayInitializer(size, wrapped, wrapped.start, wrapped.end);
        }
        return wrapped;
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
            throw new SourceException(format("Not a reference type %s", valueType.toString()), indexAccess.value);
        }
        // Check if the index type is uint64
        auto indexType = indexNode.getType();
        if (!indexType.specializableTo(AtomicType.UINT64)) {
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
                if (cast(immutable ReferenceType) leftNode.getType() is null) {
                    throw new SourceException(format("Left type must be a reference type, not %s",
                            leftNode.getType()), valueCompare.left);
                }
                auto rightNode = valueCompare.right.interpret(context).reduceLiterals();
                if (cast(immutable ReferenceType) rightNode.getType() is null) {
                    throw new SourceException(format("Right type must be a reference type, not %s",
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
        // Get the type to compare against
        auto type = typeCompare.type.interpret(context);
        auto referenceType = cast(immutable ReferenceType) type;
        if (referenceType is null) {
            throw new SourceException(format("Must be a reference type, not %s", type.toString()), typeCompare.type);
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
        if (!leftNode.getType().convertibleTo(AtomicType.BOOL)) {
            throw new SourceException(format("Left type must be bool, not %s", leftNode.getType()), logicalAnd.left);
        }
        auto rightNode = logicalAnd.right.interpret(context).reduceLiterals();
        if (!rightNode.getType().convertibleTo(AtomicType.BOOL)) {
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
        if (!leftNode.getType().convertibleTo(AtomicType.BOOL)) {
            throw new SourceException(format("Left type must be bool, not %s", leftNode.getType()), logicalOr.left);
        }
        auto rightNode = logicalOr.right.interpret(context).reduceLiterals();
        if (!rightNode.getType().convertibleTo(AtomicType.BOOL)) {
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
        if (!conditionNode.getType().convertibleTo(AtomicType.BOOL)) {
            throw new SourceException(format("Condition type must be bool, not %s", conditionNode.getType()),
                    conditional.condition);
        }
        // Get the value nodes
        auto trueNode = conditional.trueValue().interpret(context).reduceLiterals();
        auto falseNode = conditional.falseValue().interpret(context).reduceLiterals();
        return new immutable ConditionalNode(conditionNode, trueNode, falseNode, conditional.start, conditional.end);
    }

    public immutable(FlowNode) interpretTypeDefinition(Context context, TypeDefinition typeDefinition) {
        auto name = typeDefinition.name.getSource();
        auto type = typeDefinition.type.interpret(context);
        try {
            context.defineType(name, type);
        } catch (Exception exception) {
            throw new SourceException(exception.msg, typeDefinition.name);
        }
        return new immutable TypeDefinitionNode(name, type, typeDefinition.start, typeDefinition.end);
    }

    public immutable(FlowNode) interpretFunctionCallStatement(Context context, FunctionCallStatement functionCallStatement) {
        // Interpret the actual function call
        auto functionCallNode = functionCallStatement.call.interpret(context).castOrFail!(immutable FunctionCallNode);
        // Wrap it in a flow node and return it
        return new immutable FunctionCallStatementNode(functionCallNode);
    }

    public immutable(FlowNode) interpretVariableDeclaration(Context context, VariableDeclaration variableDeclaration) {
        // Get the type and value, which will vary depending on whether or not type inference is used
        Rebindable!(immutable Type) type;
        Rebindable!(immutable TypedNode) value;
        if (variableDeclaration.type is null) {
            // Use type inference, the type is the same as the value, but without literals
            value = variableDeclaration.value.interpret(context).reduceLiterals();
            type = value.getType().withoutLiteral();
        } else {
            // Use the given type
            type = variableDeclaration.type.interpret(context);
            // Interpret the value if present
            if (variableDeclaration.value !is null) {
                value = variableDeclaration.value.interpret(context).reduceLiterals();
                // Check if the types are compatible
                if (!value.getType().specializableTo(type)) {
                    throw new SourceException(format("Value type %s is not convertible to %s",
                            value.getType().toString(), type.toString()), variableDeclaration.value);
                }
            } else {
                // TODO: allow later initialization of "let" declarations
                if (variableDeclaration.kind == VariableDeclaration.Kind.LET) {
                    throw new SourceException("\"let\" variable declarations must have a value", variableDeclaration);
                }
                value = null;
            }
        }
        // Get the field name
        auto name = variableDeclaration.name.getSource();
        // A field is re-assignable if it is a "var" field
        auto reAssignable = variableDeclaration.kind == VariableDeclaration.Kind.VAR;
        //  Attempt to declare the field
        try {
            auto field = context.declareField(name, type, reAssignable);
            return new immutable VariableDeclarationNode(field, value, variableDeclaration.start, variableDeclaration.end);
        } catch (Exception exception) {
            throw new SourceException(exception.msg, variableDeclaration.name);
        }
    }

    public immutable(FlowNode) interpretAssignment(Context context, Assignment assignment) {
        assert (assignment.operator == "=");
        auto target = assignment.target.interpret(context).castOrFail!(immutable AssignableNode);
        // Check if the target is assignable (for a field)
        if (auto fieldAccess = cast(immutable FieldAccessNode) target) {
            if (!fieldAccess.field.reAssignable) {
                throw new SourceException(format("Cannot re-assign field %s", fieldAccess.field.name), fieldAccess);
            }
        }
        // Interpret the value node
        auto value = assignment.value.interpret(context).reduceLiterals();
        // Check if the types are compatible
        if (!value.getType().specializableTo(target.getType())) {
            throw new SourceException(format("Value type %s is not convertible to %s",
                    value.getType().toString(), target.getType().toString()), assignment.value);
        }
        return new immutable AssignmentNode(target, value, assignment.start, assignment.end);
    }

    public immutable(FlowNode) interpretConditionalStatement(Context context, ConditionalStatement conditionalStatement) {
        // Enter the outer block which is used to end the conditional, and contains the "else" statements (if any)
        context.enterConditionBlock();
        // Create a block node for each condition block
        auto hasFalseStatement = conditionalStatement.falseStatements.length > 0;
        immutable(FlowNode)[] conditionalStatements = [];
        foreach (i, block; conditionalStatement.conditionBlocks) {
            // Enter the conditional block
            context.enterConditionBlock();
            // Interpret the block condition
            auto condition = block.condition;
            auto conditionNode = condition.interpret(context).reduceLiterals();
            if (!conditionNode.getType().convertibleTo(AtomicType.BOOL)) {
                throw new SourceException(format("Condition type must be bool, not %s", conditionNode.getType()), condition);
            }
            // Interpret the block statements
            auto statements = block.statements;
            auto statementNodes = interpretStatements(context, statements);
            // Prepend the statements with a block jump to the end if the condition doesn't pass
            auto conditionJump = new immutable PredicateBlockJumpNode(conditionNode, true, 1, BlockJumpTarget.END,
                    condition.start, condition.end);
            statementNodes = conditionJump ~ statementNodes;
            // Append the statements with a block jump to the end of the outer block, unless this is the last one
            auto statementsEnd = statements.length <= 0 ? block.end : statements[$ - 1].end;
            if (hasFalseStatement || i < conditionalStatement.conditionBlocks.length - 1) {
                statementNodes ~= new immutable BlockJumpNode(2, BlockJumpTarget.END, statementsEnd, statementsEnd);
            }
            // Exit the conditional block
            context.exitBlock();
            // Create the condition block
            auto statementsStart = statements.length <= 0 ? block.end : statements[0].start;
            conditionalStatements ~= new immutable BlockNode(statementNodes, statementsStart, statementsEnd);
        }
        // Append the false statements
        conditionalStatements ~= interpretStatements(context, conditionalStatement.falseStatements);
        // Exit the outer condition block
        context.exitBlock();
        // Create the condition block
        return new immutable BlockNode(conditionalStatements, conditionalStatement.start, conditionalStatement.end);
    }

    public immutable(FlowNode) interpretLoopStatement(Context context, LoopStatement loopStatement) {
        // Enter the loop block
        context.enterLoopBlock();
        // Interpret the condition
        auto condition = loopStatement.condition;
        auto conditionNode = condition.interpret(context).reduceLiterals();
        if (!conditionNode.getType().convertibleTo(AtomicType.BOOL)) {
            throw new SourceException(format("Condition type must be bool, not %s", conditionNode.getType()),
                    condition);
        }
        // Interpret the statements
        auto statements = loopStatement.statements;
        auto statementNodes = interpretStatements(context, statements);
        // Prepend the statements with a block jump to the end if the loop condition doesn't pass
        auto conditionJump = new immutable PredicateBlockJumpNode(conditionNode, true, 1, BlockJumpTarget.END,
                condition.start, condition.end);
        statementNodes = conditionJump ~ statementNodes;
        // Append the statements with a block jump to the start
        auto statementsEnd = statements.length <= 0 ? loopStatement.end : statements[$ - 1].end;
        auto loopJump = new immutable BlockJumpNode(1, BlockJumpTarget.START, statementsEnd, statementsEnd);
        statementNodes ~= loopJump;
        // Exit the loop block
        context.exitBlock();
        // Create the loop block
        auto statementsStart = statements.length <= 0 ? loopStatement.end : statements[0].start;
        return new immutable BlockNode(statementNodes, statementsStart, statementsEnd);
    }

    public immutable(FlowNode) interpretFunctionDefinition(Context context, FunctionDefinition functionDefinition) {
        // Interpret the function parameters
        immutable(string)[] parameterNames = [];
        immutable(Type)[] parameterTypes = [];
        foreach (parameter; functionDefinition.parameters) {
            parameterNames ~= parameter.name.getSource();
            parameterTypes ~= parameter.type.interpret(context);
        }
        // The return type is void if missing
        auto returnType = functionDefinition.returnType is null ? VoidType.INSTANCE
                : functionDefinition.returnType.interpret(context);
        // Create the function symbol and define it in the context
        string exceptionMessage;
        auto func = collectExceptionMessage(
            context.defineFunction(functionDefinition.name.getSource(), parameterTypes, returnType),
            exceptionMessage
        );
        if (exceptionMessage !is null) {
            throw new SourceException(exceptionMessage, functionDefinition);
        }
        // Enter the function body
        context.enterFunctionImpl(func);
        // Define each parameter as a field
        foreach (i, name; parameterNames) {
            collectExceptionMessage(context.declareField(name, parameterTypes[i], false), exceptionMessage);
            if (exceptionMessage !is null) {
                throw new SourceException(exceptionMessage, functionDefinition.parameters[i]);
            }
        }
        // Interpret the statements
        auto statements = functionDefinition.statements;
        auto statementNodes = interpretStatements(context, statements);
        context.exitBlock();
        // Create the implementation block
        auto statementsStart = statements.length <= 0 ? functionDefinition.end : statements[0].start;
        auto statementsEnd = statements.length <= 0 ? functionDefinition.end : statements[$ - 1].end;
        auto blockNode = new immutable BlockNode(statementNodes, statementsStart, statementsEnd);
        // Create the function definition node
        return new immutable FunctionDefinitionNode(func, parameterNames, blockNode,
                functionDefinition.start, functionDefinition.end);
    }

    public immutable(FlowNode) interpretReturnStatement(Context context, ReturnStatement returnStatement) {
        // Get the enclosing function
        size_t blockOffset;
        auto func = context.getEnclosingFunction(blockOffset);
        if (func is null) {
            throw new SourceException("Cannot use a return statement outside of a function", returnStatement);
        }
        // Check that the return expression is specializable to the function return type
        if (func.returnType.specializableTo(VoidType.INSTANCE)) {
            if (returnStatement.value !is null) {
                throw new SourceException("Cannot have a return value for a void returning function", returnStatement.value);
            }
        } else {
            if (returnStatement.value is null) {
                throw new SourceException("Expected a return value", returnStatement);
            }
            auto valueNode = returnStatement.value.interpret(context).reduceLiterals();
            if (!valueNode.getType().specializableTo(func.returnType)) {
                throw new SourceException(format("Cannot convert the return value of type %s to %s",
                        valueNode.getType(), func.returnType), returnStatement.value);
            }
        }
        // TODO: some way of placing the return value on the stack
        return new immutable BlockJumpNode(blockOffset, BlockJumpTarget.END, returnStatement.start, returnStatement.end);
    }

    private static immutable(FlowNode)[] interpretStatements(Context context, Statement[] statements) {
        immutable(FlowNode)[] statementNodes = [];
        foreach (statement; statements) {
            statementNodes ~= statement.interpret(context);
        }
        return statementNodes;
    }
}
