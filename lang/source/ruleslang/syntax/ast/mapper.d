module ruleslang.syntax.ast.mapper;

import std.traits;

import ruleslang.syntax.token;
import ruleslang.syntax.ast.type;
import ruleslang.syntax.ast.expression;

public abstract class ExpresionMapper {
    public abstract Type mapNamedType(NamedType expression) {
        return expression;
    }

    public abstract Expression mapBooleanLiteral(BooleanLiteral expression) {
        return expression;
    }

    public abstract Expression mapStringLiteral(StringLiteral expression) {
        return expression;
    }

    public abstract Expression mapIntegerLiteral(IntegerLiteral expression) {
        return expression;
    }

    public abstract Expression mapFloatLiteral(FloatLiteral expression) {
        return expression;
    }

    public abstract Expression mapNameReference(NameReference expression) {
        return expression;
    }

    public abstract Expression mapCompositeLiteral(CompositeLiteral expression) {
        return expression;
    }

    public abstract Expression mapInitializer(Initializer expression) {
        return expression;
    }

    public abstract Expression mapContextMemberAccess(ContextMemberAccess expression) {
        return expression;
    }

    public abstract Expression mapMemberAccess(MemberAccess expression) {
        return expression;
    }

    public abstract Expression mapArrayAccess(ArrayAccess expression) {
        return expression;
    }

    public abstract Expression mapFunctionCall(FunctionCall expression) {
        return expression;
    }

    public abstract Expression mapSign(Sign expression) {
        return expression;
    }

    public abstract Expression mapLogicalNot(LogicalNot expression) {
        return expression;
    }

    public abstract Expression mapBitwiseNot(BitwiseNot expression) {
        return expression;
    }

    public abstract Expression mapExponent(Exponent expression) {
        return expression;
    }

    public abstract Expression mapInfix(Infix expression) {
        return expression;
    }

    public abstract Expression mapMultiply(Multiply expression) {
        return expression;
    }

    public abstract Expression mapAdd(Add expression) {
        return expression;
    }

    public abstract Expression mapShift(Shift expression) {
        return expression;
    }

    public abstract Expression mapCompare(Compare expression) {
        return expression;
    }

    public abstract Expression mapBitwiseAnd(BitwiseAnd expression) {
        return expression;
    }

    public abstract Expression mapBitwiseXor(BitwiseXor expression) {
        return expression;
    }

    public abstract Expression mapBitwiseOr(BitwiseOr expression) {
        return expression;
    }

    public abstract Expression mapLogicalAnd(LogicalAnd expression) {
        return expression;
    }

    public abstract Expression mapLogicalXor(LogicalXor expression) {
        return expression;
    }

    public abstract Expression mapLogicalOr(LogicalOr expression) {
        return expression;
    }

    public abstract Expression mapConcatenate(Concatenate expression) {
        return expression;
    }

    public abstract Expression mapRange(Range expression) {
        return expression;
    }

    public abstract Expression mapConditional(Conditional expression) {
        return expression;
    }
}
