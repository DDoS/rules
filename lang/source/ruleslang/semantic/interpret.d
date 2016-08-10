module ruleslang.semantic.interpret;

import ruleslang.syntax.source;
import ruleslang.syntax.token;
import ruleslang.syntax.ast.expression;
import ruleslang.semantic.tree;

public immutable class Interpreter {
    public static immutable Interpreter INSTANCE = new immutable Interpreter();

    private this() {
    }

    public immutable(Node) interpretBooleanLiteral(BooleanLiteral boolean) {
        return new immutable BooleanLiteralNode(boolean.getValue());
    }

    public immutable(Node) interpretStringLiteral(StringLiteral expression) {
        return new immutable StringLiteralNode(expression.getValue());
    }

    public immutable(Node) interpretCharacterLiteral(CharacterLiteral expression) {
        return new immutable IntegerLiteralNode(cast(ulong) expression.getValue());
    }

    public immutable(Node) interpretSignedIntegerLiteral(SignedIntegerLiteral integer) {
        bool overflow;
        auto value = integer.getValue(false, overflow);
        if (overflow) {
            throw new SourceException("Signed integer overflow", integer);
        }
        return new immutable IntegerLiteralNode(value);
    }

    public immutable(Node) interpretUnsignedIntegerLiteral(UnsignedIntegerLiteral integer) {
        bool overflow;
        auto value = integer.getValue(overflow);
        if (overflow) {
            throw new SourceException("Unsigned integer overflow", integer);
        }
        return new immutable IntegerLiteralNode(value);
    }

    public immutable(Node) interpretFloatLiteral(FloatLiteral floating) {
        bool overflow;
        auto value = floating.getValue(overflow);
        if (overflow) {
            throw new SourceException("Floating point overflow/underflow", floating);
        }
        return new immutable FloatLiteralNode(value);
    }

    public immutable(Node) interpretNameReference(NameReference expression) {
        return NullNode.INSTANCE;
    }

    public immutable(Node) interpretCompositeLiteral(CompositeLiteral expression) {
        return NullNode.INSTANCE;
    }

    public immutable(Node) interpretInitializer(Initializer expression) {
        return NullNode.INSTANCE;
    }

    public immutable(Node) interpretContextMemberAccess(ContextMemberAccess expression) {
        return NullNode.INSTANCE;
    }

    public immutable(Node) interpretMemberAccess(MemberAccess expression) {
        return NullNode.INSTANCE;
    }

    public immutable(Node) interpretArrayAccess(ArrayAccess expression) {
        return NullNode.INSTANCE;
    }

    public immutable(Node) interpretFunctionCall(FunctionCall expression) {
        return NullNode.INSTANCE;
    }

    public immutable(Node) interpretSign(Sign sign) {
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

    public immutable(Node) interpretLogicalNot(LogicalNot expression) {
        return NullNode.INSTANCE;
    }

    public immutable(Node) interpretBitwiseNot(BitwiseNot expression) {
        return NullNode.INSTANCE;
    }

    public immutable(Node) interpretExponent(Exponent expression) {
        return NullNode.INSTANCE;
    }

    public immutable(Node) interpretInfix(Infix expression) {
        return NullNode.INSTANCE;
    }

    public immutable(Node) interpretMultiply(Multiply expression) {
        return NullNode.INSTANCE;
    }

    public immutable(Node) interpretAdd(Add expression) {
        return NullNode.INSTANCE;
    }

    public immutable(Node) interpretShift(Shift expression) {
        return NullNode.INSTANCE;
    }

    public immutable(Node) interpretCompare(Compare expression) {
        return NullNode.INSTANCE;
    }

    public immutable(Node) interpretValueCompare(ValueCompare expression) {
        return NullNode.INSTANCE;
    }

    public immutable(Node) interpretTypeCompare(TypeCompare expression) {
        return NullNode.INSTANCE;
    }

    public immutable(Node) interpretBitwiseAnd(BitwiseAnd expression) {
        return NullNode.INSTANCE;
    }

    public immutable(Node) interpretBitwiseXor(BitwiseXor expression) {
        return NullNode.INSTANCE;
    }

    public immutable(Node) interpretBitwiseOr(BitwiseOr expression) {
        return NullNode.INSTANCE;
    }

    public immutable(Node) interpretLogicalAnd(LogicalAnd expression) {
        return NullNode.INSTANCE;
    }

    public immutable(Node) interpretLogicalXor(LogicalXor expression) {
        return NullNode.INSTANCE;
    }

    public immutable(Node) interpretLogicalOr(LogicalOr expression) {
        return NullNode.INSTANCE;
    }

    public immutable(Node) interpretConcatenate(Concatenate expression) {
        return NullNode.INSTANCE;
    }

    public immutable(Node) interpretRange(Range expression) {
        return NullNode.INSTANCE;
    }

    public immutable(Node) interpretConditional(Conditional expression) {
        return NullNode.INSTANCE;
    }
}
