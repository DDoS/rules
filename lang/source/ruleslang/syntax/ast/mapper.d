module ruleslang.syntax.ast.mapper;

import ruleslang.syntax.token;
import ruleslang.syntax.ast.type;
import ruleslang.syntax.ast.expression;
import ruleslang.syntax.ast.statement;

public abstract class TypeMapper {
    public Type mapNamedType(NamedType type) {
        return type;
    }
}

public abstract class ExpressionMapper : TypeMapper {
    public Expression mapBooleanLiteral(BooleanLiteral expression) {
        return expression;
    }

    public Expression mapStringLiteral(StringLiteral expression) {
        return expression;
    }

    public Expression mapSignedIntegerLiteral(SignedIntegerLiteral expression) {
        return expression;
    }

    public Expression mapUnsignedIntegerLiteral(UnsignedIntegerLiteral expression) {
        return expression;
    }

    public Expression mapFloatLiteral(FloatLiteral expression) {
        return expression;
    }

    public Expression mapNameReference(NameReference expression) {
        return expression;
    }

    public Expression mapCompositeLiteral(CompositeLiteral expression) {
        return expression;
    }

    public Expression mapInitializer(Initializer expression) {
        return expression;
    }

    public Expression mapContextMemberAccess(ContextMemberAccess expression) {
        return expression;
    }

    public Expression mapMemberAccess(MemberAccess expression) {
        return expression;
    }

    public Expression mapArrayAccess(ArrayAccess expression) {
        return expression;
    }

    public Expression mapFunctionCall(FunctionCall expression) {
        return expression;
    }

    public Expression mapSign(Sign expression) {
        return expression;
    }

    public Expression mapLogicalNot(LogicalNot expression) {
        return expression;
    }

    public Expression mapBitwiseNot(BitwiseNot expression) {
        return expression;
    }

    public Expression mapExponent(Exponent expression) {
        return expression;
    }

    public Expression mapInfix(Infix expression) {
        return expression;
    }

    public Expression mapMultiply(Multiply expression) {
        return expression;
    }

    public Expression mapAdd(Add expression) {
        return expression;
    }

    public Expression mapShift(Shift expression) {
        return expression;
    }

    public Expression mapCompare(Compare expression) {
        return expression;
    }

    public Expression mapValueCompare(ValueCompare expression) {
        return expression;
    }

    public Expression mapTypeCompare(TypeCompare expression) {
        return expression;
    }

    public Expression mapBitwiseAnd(BitwiseAnd expression) {
        return expression;
    }

    public Expression mapBitwiseXor(BitwiseXor expression) {
        return expression;
    }

    public Expression mapBitwiseOr(BitwiseOr expression) {
        return expression;
    }

    public Expression mapLogicalAnd(LogicalAnd expression) {
        return expression;
    }

    public Expression mapLogicalXor(LogicalXor expression) {
        return expression;
    }

    public Expression mapLogicalOr(LogicalOr expression) {
        return expression;
    }

    public Expression mapConcatenate(Concatenate expression) {
        return expression;
    }

    public Expression mapRange(Range expression) {
        return expression;
    }

    public Expression mapConditional(Conditional expression) {
        return expression;
    }
}

public abstract class StatementMapper : ExpressionMapper {
    public Statement mapInitializerAssignment(InitializerAssignment statement) {
        return statement;
    }

    public Statement mapAssignment(Assignment statement) {
        return statement;
    }
}
