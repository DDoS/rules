module ruleslang.semantic.interpret;

import std.format : format;

import ruleslang.syntax.source;
import ruleslang.syntax.token;
import ruleslang.syntax.ast.expression;
import ruleslang.semantic.tree;
import ruleslang.semantic.context;
import ruleslang.semantic.type;
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

    public immutable(FieldAccessNode) interpretNameReference(Context context, NameReference nameReference) {
        auto field = context.resolveField(nameReference.name[0].getSource());
        if (field is null) {
            // TODO: semantic exceptions
            throw new Exception(format("No field found for name %s", nameReference.toString()));
        }
        // TODO: resolve subsequent name parts as type membes
        return new immutable FieldAccessNode(field);
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
        auto nameReference = cast(NameReference) call.value;
        if (nameReference !is null && nameReference.name.length == 1) {
            // A function call name should have only one part
            auto simpleName = nameReference.name[0].getSource();
            auto field = context.resolveField(simpleName);
            auto func = context.resolveFunction(simpleName, argumentTypes);
            // It should not resolve to both a field and a function
            if (field !is null && func !is null) {
                throw new Exception(format("Found a field and a function for the name %s", simpleName));
            }
            if (field !is null) {
                // Treat a field like a value
                return interpretValueCall(new immutable FieldAccessNode(field), argumentNodes);
            }
            if (func is null) {
                // Found nothing!
                // TODO: semantic exceptions
                throw new Exception(format("No function found for call %s(%s)", simpleName, argumentTypes.join!", "()));
            }
            // It's a function call
            return new immutable FunctionCallNode(func, argumentNodes);
        }
        // The value isn't a name, just interpret it
        return interpretValueCall(call.value.interpret(context), argumentNodes);
    }

    private immutable(TypedNode) interpretValueCall(immutable(Node) value, immutable(Node)[] argumentNodes) {
        assert (0);
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
