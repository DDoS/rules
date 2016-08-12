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

    public immutable(IntegerLiteralNode) interpretCharacterLiteral(Context context, CharacterLiteral expression) {
        return new immutable IntegerLiteralNode(cast(ulong) expression.getValue());
    }

    public immutable(IntegerLiteralNode) interpretSignedIntegerLiteral(Context context, SignedIntegerLiteral integer) {
        bool overflow;
        auto value = integer.getValue(false, overflow);
        if (overflow) {
            throw new SourceException("Signed integer overflow", integer);
        }
        return new immutable IntegerLiteralNode(value);
    }

    public immutable(IntegerLiteralNode) interpretUnsignedIntegerLiteral(Context context, UnsignedIntegerLiteral integer) {
        bool overflow;
        auto value = integer.getValue(overflow);
        if (overflow) {
            throw new SourceException("Unsigned integer overflow", integer);
        }
        return new immutable IntegerLiteralNode(value);
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
        return interpretNameReference(context, nameReference.name);
    }

    private immutable(TypedNode) interpretNameReference(Context context, Identifier[] name) {
        // The first name is always that of a field
        auto field = context.resolveField(name[0].getSource());
        if (field is null) {
            // TODO: semantic exceptions
            throw new Exception(format("No field found for name %s", name[0].getSource()));
        }
        immutable(TypedNode) fieldAccess = new immutable FieldAccessNode(field);
        // If the name has more parts, treat the next as a structure member accesses
        immutable(TypedNode)* lastAccess = &fieldAccess;
        foreach (part; name[1 .. $]) {
            // First check the last access is a structure type (otherwise it has no members)
            auto lastAccessType = (*lastAccess).getType();
            auto structureType = cast(immutable StructureType) lastAccessType;
            if (structureType is null) {
                // TODO: semantic exceptions
                throw new Exception(format("Type %s has no members", lastAccessType.toString()));
            }
            // Now if it is, check for the memeber
            auto memberName = part.getSource();
            auto member = structureType.getMemberType(memberName);
            if (member is null) {
                // TODO: semantic exceptions
                throw new Exception(format("No member named %s in type %s", memberName, structureType.toString()));
            }
            // Wrap the last access in the member access
            immutable(TypedNode) memberAccess = new immutable MemberAccessNode(*lastAccess, memberName);
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

    public immutable(TypedNode) interpretMemberAccess(Context context, MemberAccess expression) {
        return NullNode.INSTANCE;
    }

    public immutable(TypedNode) interpretArrayAccess(Context context, ArrayAccess expression) {
        return NullNode.INSTANCE;
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
        auto nameReference = cast(NameReference) value;
        if (nameReference is null) {
            // If the value isn't a name reference, we might have a member access
            // Either the accessed member is a function type or UFCS is being used
            auto memberAccess = cast(MemberAccess) value;
            if (memberAccess is null) {
                // No member, this is just a value call (no function name is given)
                return interpretValueCall(value.interpret(context), argumentNodes, argumentTypes);
            }
            // Otherwise the value is being called with the member name as the function name
            auto lastName = memberAccess.name.getSource();
            auto valueNode = memberAccess.value.interpret(context);
            return interpretValueFunctionCall(context, lastName, valueNode, argumentNodes, argumentTypes);
        }
        // We treat simple and multi-part name references separately
        auto name = nameReference.name;
        if (name.length == 1) {
            // Simple name references require disambiguation between field and functions
            return interpretSimpleFunctionCall(context, name[0].getSource(), argumentNodes, argumentTypes);
        }
        // Multi-part name references require disambiguation between members and functions
        auto lastName = name[$ - 1].getSource();
        auto valueNode = interpretNameReference(context, name[0 .. $ - 1]);
        return interpretValueFunctionCall(context, lastName, valueNode, argumentNodes, argumentTypes);
    }

    private immutable(TypedNode) interpretSimpleFunctionCall(Context context, string name,
            immutable(TypedNode)[] argumentNodes, immutable(Type)[] argumentTypes) {
        // If the value is a single part name, then it is either a field
        // or a function
        auto field = context.resolveField(name);
        auto func = context.resolveFunction(name, argumentTypes);
        // It should not resolve to both a field and a function
        if (field !is null && func !is null) {
            throw new Exception(format("Found a field and a function for the name %s", name));
        }
        // Treat a field like a value
        if (field !is null) {
            return interpretValueCall(new immutable FieldAccessNode(field), argumentNodes, argumentTypes);
        }
        // Otherwise use the function
        if (func is null) {
            functionNotFound(name, argumentTypes);
        }
        return new immutable FunctionCallNode(func, argumentNodes);
    }

    private immutable(TypedNode) interpretValueFunctionCall(Context context, string name, immutable TypedNode valueNode,
            immutable(TypedNode)[] argumentNodes, immutable(Type)[] argumentTypes) {
        // If the value is a multi-part name, then all but the last part should
        // resolve to some value. The last name is either a structure member or
        // the name of a function (when using UFCS). The member has priority
        auto structureType = cast(immutable StructureType) valueNode.getType();
        if (structureType !is null) {
            // If the name points to a structure, check if the last part is a member
            auto memberType = structureType.getMemberType(name);
            if (memberType !is null) {
                return interpretValueCall(new immutable MemberAccessNode(valueNode, name), argumentNodes, argumentTypes);
            }
        }
        // Otherwise apply the UFCS transformation: the last part becomes the function name
        // and value of the previous parts become the first argument of the call
        // Example: a.b.c(d, e) -> c(a.b, d, e)
        argumentNodes = valueNode ~ argumentNodes;
        argumentTypes = valueNode.getType() ~ argumentTypes;
        auto func = context.resolveFunction(name, argumentTypes);
        if (func is null) {
            functionNotFound(name, argumentTypes);
        }
        return new immutable FunctionCallNode(func, argumentNodes);
    }

    private immutable(TypedNode) interpretValueCall(immutable(TypedNode) valueNode, immutable(TypedNode)[] argumentNodes,
            immutable(Type)[] argumentTypes) {
        /*
            TODO: when function type are added, check if value is one and call it, instead of doing UFCS immediately
            auto functionType = cast(immutable FunctionType) valueNode.getType();
            if (functionType is null) {
                // TODO: semantic exceptions
                throw new Exception(format("Type %s is not callable", valueNode.getType()));
            }
            if (!functionType.isApplicable(argumentNodes)) {
                // TODO: semantic exceptions
                throw new Exception(format("Type %s is not callable with %s", valueNode.getType(), argumentTypes.join!", "()));
            }
            return new immutable ValueCallNode(valueNode, argumentNodes);
        */
        // TODO: semantic exceptions
        throw new Exception(format("Type %s is not callable", valueNode.getType()));
    }

    private immutable(FunctionCallNode) functionNotFound(string name, immutable(Type)[] argumentTypes) {
        // TODO: semantic exceptions
        throw new Exception(format("No function found for call %s(%s)", name, argumentTypes.join!", "()));
    }

    public immutable(TypedNode) interpretSign(Context context, Sign sign) {
        auto integer = cast(SignedIntegerLiteral) sign.inner;
        if (integer && integer.radix == 10) {
            bool overflow;
            auto value = integer.getValue(sign.operator == "-", overflow);
            if (overflow) {
                throw new SourceException("Signed integer overflow", sign);
            }
            return new immutable IntegerLiteralNode(value);
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
