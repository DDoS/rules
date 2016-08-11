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
        assert (0);
    }

    public immutable(Node) interpretBitwiseNot(BitwiseNot expression) {
        assert (0);
    }

    public immutable(Node) interpretExponent(Exponent expression) {
        assert (0);
    }

    public immutable(Node) interpretInfix(Infix expression) {
        assert (0);
    }

    public immutable(Node) interpretMultiply(Multiply expression) {
        assert (0);
    }

    public immutable(Node) interpretAdd(Add expression) {
        assert (0);
    }

    public immutable(Node) interpretShift(Shift expression) {
        assert (0);
    }

    public immutable(Node) interpretCompare(Compare expression) {
        assert (0);
    }

    public immutable(Node) interpretValueCompare(ValueCompare expression) {
        assert (0);
    }

    public immutable(Node) interpretTypeCompare(TypeCompare expression) {
        return NullNode.INSTANCE;
    }

    public immutable(Node) interpretBitwiseAnd(BitwiseAnd expression) {
        assert (0);
    }

    public immutable(Node) interpretBitwiseXor(BitwiseXor expression) {
        assert (0);
    }

    public immutable(Node) interpretBitwiseOr(BitwiseOr expression) {
        assert (0);
    }

    public immutable(Node) interpretLogicalAnd(LogicalAnd expression) {
        assert (0);
    }

    public immutable(Node) interpretLogicalXor(LogicalXor expression) {
        assert (0);
    }

    public immutable(Node) interpretLogicalOr(LogicalOr expression) {
        assert (0);
    }

    public immutable(Node) interpretConcatenate(Concatenate expression) {
        assert (0);
    }

    public immutable(Node) interpretRange(Range expression) {
        assert (0);
    }

    public immutable(Node) interpretConditional(Conditional expression) {
        assert (0);
    }
}
