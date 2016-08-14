module ruleslang.semantic.interpret;

import std.format : format;

import ruleslang.syntax.source;
import ruleslang.syntax.token;
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

    public immutable(BooleanLiteralNode) interpretBooleanLiteral(Context context, BooleanLiteral boolean) {
        return new immutable BooleanLiteralNode(boolean.getValue());
    }

    public immutable(StringLiteralNode) interpretStringLiteral(Context context, StringLiteral expression) {
        return new immutable StringLiteralNode(expression.getValue());
    }

    public immutable(UnsignedIntegerLiteralNode) interpretCharacterLiteral(Context context,
            CharacterLiteral expression) {
        return new immutable UnsignedIntegerLiteralNode(cast(ulong) expression.getValue());
    }

    public immutable(SignedIntegerLiteralNode) interpretSignedIntegerLiteral(Context context,
            SignedIntegerLiteral integer) {
        bool overflow;
        auto value = integer.getValue(false, overflow);
        if (overflow) {
            throw new SourceException("Signed integer overflow", integer);
        }
        return new immutable SignedIntegerLiteralNode(value);
    }

    public immutable(UnsignedIntegerLiteralNode) interpretUnsignedIntegerLiteral(Context context,
            UnsignedIntegerLiteral integer) {
        bool overflow;
        auto value = integer.getValue(overflow);
        if (overflow) {
            throw new SourceException("Unsigned integer overflow", integer);
        }
        return new immutable UnsignedIntegerLiteralNode(value);
    }

    public immutable(FloatLiteralNode) interpretFloatLiteral(Context context, FloatLiteral floating) {
        bool overflow;
        auto value = floating.getValue(overflow);
        if (overflow) {
            throw new SourceException("Floating point overflow/underflow", floating);
        }
        return new immutable FloatLiteralNode(value);
    }

    public immutable(TypedNode) interpretNameReference(Context context, NameReference nameReference) {
        auto name = nameReference.name;
        // The first name is always that of a field
        auto firstPart = name[0];
        auto field = context.resolveField(firstPart.getSource());
        if (field is null) {
            throw new SourceException(format("No field found for name %s", firstPart.getSource()), firstPart);
        }
        immutable(TypedNode) fieldAccess = new immutable FieldAccessNode(field);
        // If the name has more parts, treat the next as a structure member accesses
        immutable(TypedNode)* lastAccess = &fieldAccess;
        foreach (i, part; name[1 .. $]) {
            immutable(TypedNode) memberAccess = interpretMemberAccess(new NameReference(name[0 .. i + 1]), *lastAccess, part);
            lastAccess = &memberAccess;
        }
        return *lastAccess;
    }

    public immutable(TypedNode) interpretCompositeLiteral(Context context, CompositeLiteral expression) {
        return NullNode.INSTANCE;
    }

    public immutable(TypedNode) interpretInitializer(Context context, Initializer expression) {
        return NullNode.INSTANCE;
    }

    public immutable(TypedNode) interpretContextMemberAccess(Context context, ContextMemberAccess expression) {
        return NullNode.INSTANCE;
    }

    public immutable(MemberAccessNode) interpretMemberAccess(Context context, MemberAccess memberAccess) {
        auto valueNode = memberAccess.value.interpret(context);
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
        return new immutable MemberAccessNode(valueNode, memberName);
    }

    public immutable(TypedNode) interpretArrayAccess(Context context, ArrayAccess arrayAccess) {
        // Interpret both the value and the index
        auto valueNode = arrayAccess.value.interpret(context);
        auto indexNode = arrayAccess.index.interpret(context);
        // Check if the value type is an array
        auto valueType = valueNode.getType();
        auto arrayType = cast(immutable ArrayType) valueType;
        if (arrayType is null) {
            throw new SourceException(format("Not an array type %s", valueType.toString()), arrayAccess.value);
        }
        // Check if the index type is a uint64
        auto indexType = indexNode.getType();
        auto conversions = new TypeConversionChain();
        if (!indexType.convertibleTo(AtomicType.UINT64, conversions)) {
            throw new SourceException(format("Index type %s is not convertible to uint64", indexType.toString()),
                    arrayAccess.index);
        }
        // Attempt to create the node. This can fail if the index is out of range (determined through literal types)
        string exceptionMessage;
        auto node = collectExceptionMessage(new immutable ArrayIndexNode(valueNode, indexNode), exceptionMessage);
        if (exceptionMessage !is null) {
            throw new SourceException(exceptionMessage, arrayAccess);
        }
        return node;
    }

    public immutable(TypedNode) interpretFunctionCall(Context context, FunctionCall call) {
        // Interpret the argument and get their types
        immutable(TypedNode)[] argumentNodes;
        immutable(Type)[] argumentTypes;
        argumentNodes.reserve(call.arguments.length);
        argumentTypes.reserve(call.arguments.length);
        foreach (argument; call.arguments) {
            auto node = argument.interpret(context);
            argumentNodes ~= node;
            argumentTypes ~= node.getType();
        }
        // Now figure out if the call value is the name of a function or an actual value
        auto value = call.value;
        auto end = call.end;
        auto nameReference = cast(NameReference) value;
        if (nameReference is null) {
            // If the value isn't a name reference, we might have a member access
            // Either the accessed member is a function type or UFCS is being used
            auto memberAccess = cast(MemberAccess) value;
            if (memberAccess is null) {
                // No member, this is just a value call (no function name is given)
                return interpretValueCall(value, value.interpret(context), argumentNodes, argumentTypes, end);
            }
            // Otherwise the value is being called with the member name as the function name
            auto lastName = memberAccess.name;
            auto memberValue = memberAccess.value;
            auto valueNode = memberValue.interpret(context);
            return interpretValueFunctionCall(context, memberValue, lastName, valueNode, argumentNodes, argumentTypes, end);
        }
        // We treat simple and multi-part name references separately
        auto name = nameReference.name;
        if (name.length == 1) {
            // Simple name references require disambiguation between field and functions
            return interpretSimpleFunctionCall(context, nameReference, argumentNodes, argumentTypes, end);
        }
        // Multi-part name references require disambiguation between members and functions
        auto firstPart = new NameReference(name[0 .. $ - 1]);
        auto valueNode = interpretNameReference(context, firstPart);
        return interpretValueFunctionCall(context, firstPart, name[$ - 1], valueNode, argumentNodes, argumentTypes, end);
    }

    private static immutable(TypedNode) interpretSimpleFunctionCall(Context context, NameReference nameReference,
            immutable(TypedNode)[] argumentNodes, immutable(Type)[] argumentTypes, size_t end) {
        // If the value is a single part name, then it is either a field or a function
        assert (nameReference.name.length == 1);
        auto name = nameReference.name[0];
        auto nameSource = name.getSource();
        auto field = context.resolveField(nameSource);
        auto func = resolveFunction(context, name, argumentTypes, end);
        // It should not resolve to both a field and a function
        if (field !is null && func !is null) {
            throw new SourceException(format("Found a field and a function for the name %s", nameSource), nameReference);
        }
        // Treat a field like a value
        if (field !is null) {
            auto valueCallNode = new immutable FieldAccessNode(field);
            return interpretValueCall(nameReference, valueCallNode, argumentNodes, argumentTypes, end);
        }
        // Otherwise use the function
        if (func is null) {
            functionNotFound(name, argumentTypes, end);
        }
        return new immutable FunctionCallNode(func, argumentNodes);
    }

    private static immutable(TypedNode) interpretValueFunctionCall(Context context, Expression value, Identifier name,
            immutable TypedNode valueNode, immutable(TypedNode)[] argumentNodes, immutable(Type)[] argumentTypes, size_t end) {
        // If the value is a multi-part name, then all but the last part should
        // resolve to some value. The last name is either a structure member or
        // the name of a function (when using UFCS). The member has priority
        auto structureType = cast(immutable StructureType) valueNode.getType();
        if (structureType !is null) {
            // If the name points to a structure, check if the last part is a member
            auto nameSource = name.getSource();
            auto memberType = structureType.getMemberType(nameSource);
            if (memberType !is null) {
                auto valueCallNode = new immutable MemberAccessNode(valueNode, nameSource);
                return interpretValueCall(value, valueCallNode, argumentNodes, argumentTypes, end);
            }
        }
        // Otherwise apply the UFCS transformation: the last part becomes the function name
        // and value of the previous parts become the first argument of the call
        // Example: a.b.c(d, e) -> c(a.b, d, e)
        argumentNodes = valueNode ~ argumentNodes;
        argumentTypes = valueNode.getType() ~ argumentTypes;
        auto func = resolveFunction(context, name, argumentTypes, end);
        if (func is null) {
            functionNotFound(name, argumentTypes, end);
        }
        return new immutable FunctionCallNode(func, argumentNodes);
    }

    private static immutable(Function) resolveFunction(Context context, Identifier name, immutable(Type)[] argumentTypes,
            size_t end) {
        string exceptionMessage;
        auto func = collectExceptionMessage(context.resolveFunction(name.getSource(), argumentTypes), exceptionMessage);
        if (exceptionMessage !is null) {
            throw new SourceException(exceptionMessage, name.start, end);
        }
        return func;
    }

    private static immutable(TypedNode) interpretValueCall(Expression value, immutable(TypedNode) valueNode,
            immutable(TypedNode)[] argumentNodes, immutable(Type)[] argumentTypes, size_t end) {
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

    private static immutable(FunctionCallNode) functionNotFound(Identifier name, immutable(Type)[] argumentTypes, size_t end) {
        throw new SourceException(format("No function found for call %s(%s)", name.getSource(), argumentTypes.join!", "()),
                name.start, end);
    }

    public immutable(TypedNode) interpretSign(Context context, Sign sign) {
        auto integer = cast(SignedIntegerLiteral) sign.inner;
        if (integer && integer.radix == 10) {
            bool overflow;
            auto value = integer.getValue(sign.operator == "-", overflow);
            if (overflow) {
                throw new SourceException("Signed integer overflow", sign);
            }
            return new immutable SignedIntegerLiteralNode(value);
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

    public immutable(TypedNode) interpretValueCompare(Context context, ValueCompare expression) {
        assert (0);
    }

    public immutable(TypedNode) interpretTypeCompare(Context context, TypeCompare expression) {
        return NullNode.INSTANCE;
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

    public immutable(TypedNode) interpretLogicalAnd(Context context, LogicalAnd expression) {
        assert (0);
    }

    public immutable(TypedNode) interpretLogicalXor(Context context, LogicalXor expression) {
        assert (0);
    }

    public immutable(TypedNode) interpretLogicalOr(Context context, LogicalOr expression) {
        assert (0);
    }

    public immutable(TypedNode) interpretConcatenate(Context context, Concatenate expression) {
        assert (0);
    }

    public immutable(TypedNode) interpretRange(Context context, Range expression) {
        assert (0);
    }

    public immutable(TypedNode) interpretConditional(Context context, Conditional expression) {
        assert (0);
    }
}
