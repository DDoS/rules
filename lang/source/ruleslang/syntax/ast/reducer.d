module ruleslang.syntax.ast.reducer;

import ruleslang.syntax.token;
import ruleslang.syntax.ast.type;
import ruleslang.syntax.ast.expression;
import ruleslang.syntax.ast.statement;

public abstract class TypeReducer(T) {
    public T mapNamedType(NamedType type, T t) {
        return t;
    }
}

public abstract class ExpressionReducer(E) {
    public E reduceBooleanLiteral(BooleanLiteral expression, E e) {
        return e;
    }

    public E reduceStringLiteral(StringLiteral expression, E e) {
        return e;
    }

    public E reduceIntegerLiteral(IntegerLiteral expression, E e) {
        return e;
    }

    public E reduceFloatLiteral(FloatLiteral expression, E e) {
        return e;
    }

    public E reduceNameReference(NameReference expression, E e) {
        return e;
    }

    public E reduceCompositeLiteral(CompositeLiteral expression, E e) {
        return e;
    }

    public E reduceInitializer(Initializer expression, E e) {
        return e;
    }

    public E reduceContextMemberAccess(ContextMemberAccess expression, E e) {
        return e;
    }

    public E reduceMemberAccess(MemberAccess expression, E e) {
        return e;
    }

    public E reduceArrayAccess(ArrayAccess expression, E e) {
        return e;
    }

    public E reduceFunctionCall(FunctionCall expression, E e) {
        return e;
    }

    public E reduceSign(Sign expression, E e) {
        return e;
    }

    public E reduceLogicalNot(LogicalNot expression, E e) {
        return e;
    }

    public E reduceBitwiseNot(BitwiseNot expression, E e) {
        return e;
    }

    public E reduceExponent(Exponent expression, E e) {
        return e;
    }

    public E reduceInfix(Infix expression, E e) {
        return e;
    }

    public E reduceMultiply(Multiply expression, E e) {
        return e;
    }

    public E reduceAdd(Add expression, E e) {
        return e;
    }

    public E reduceShift(Shift expression, E e) {
        return e;
    }

    public E reduceCompare(Compare expression, E e) {
        return e;
    }

    public E reduceValueCompare(ValueCompare expression, E e) {
        return e;
    }

    public E reduceTypeCompare(TypeCompare expression, E e) {
        return e;
    }

    public E reduceBitwiseAnd(BitwiseAnd expression, E e) {
        return e;
    }

    public E reduceBitwiseXor(BitwiseXor expression, E e) {
        return e;
    }

    public E reduceBitwiseOr(BitwiseOr expression, E e) {
        return e;
    }

    public E reduceLogicalAnd(LogicalAnd expression, E e) {
        return e;
    }

    public E reduceLogicalXor(LogicalXor expression, E e) {
        return e;
    }

    public E reduceLogicalOr(LogicalOr expression, E e) {
        return e;
    }

    public E reduceConcatenate(Concatenate expression, E e) {
        return e;
    }

    public E reduceRange(Range expression, E e) {
        return e;
    }

    public E reduceConditional(Conditional expression, E e) {
        return e;
    }
}

public abstract class StatementReducer(S) {
    public S reduceInitializerAssignment(InitializerAssignment statement, S s) {
        return s;
    }

    public S reduceAssignment(Assignment statement, S s) {
        return s;
    }
}
