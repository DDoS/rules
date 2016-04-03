module ruleslang.semantic.interpret;

import ruleslang.syntax.token;
import ruleslang.syntax.ast.expression;
import ruleslang.semantic.tree;

public immutable class Interpreter {
    public static immutable Interpreter INSTANCE = new immutable Interpreter();

    private this() {
    }

    public immutable(Node) interpretBooleanLiteral(BooleanLiteral expression) {
        return NullNode.INSTANCE;
    }

    public immutable(Node) interpretStringLiteral(StringLiteral expression) {
        return NullNode.INSTANCE;
    }

    public immutable(Node) interpretIntegerLiteral(IntegerLiteral expression) {
        
        return NullNode.INSTANCE;
    }

    public immutable(Node) interpretFloatLiteral(FloatLiteral expression) {
        return NullNode.INSTANCE;
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

    public immutable(Node) interpretSign(Sign expression) {
        return NullNode.INSTANCE;
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
