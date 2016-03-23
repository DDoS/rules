module ruleslang.semantic.litreduce;

import ruleslang.syntax.token;
import ruleslang.syntax.ast.expression;
import ruleslang.syntax.ast.statement;
import ruleslang.syntax.ast.mapper;

public Statement reduceLiterals(Statement target) {
    return target.accept(new LiteralReducer());
}

private class LiteralReducer : StatementMapper {
    public override Expression mapSign(Sign sign) {
        // For decimal integer literals, apply sign negation
        // in source because abs(int_min) != int_max
        auto integerLiteral = cast(IntegerLiteral) sign.inner;
        if (integerLiteral) {
            if (sign.operator == "-") {
                if (integerLiteral.radix == 10) {
                    integerLiteral.negateSign();
                } else {
                    return new IntegerLiteral(-integerLiteral.getValue());
                }
            }
            return integerLiteral;
        }
        // For floats, apply to the value instead
        auto floatLiteral = cast(FloatLiteral) sign.inner;
        if (floatLiteral) {
            if (sign.operator == "-") {
                return new FloatLiteral(-floatLiteral.getValue());
            }
            return floatLiteral;
        }
        // Anything else is untouched
        return sign;
    }

    public override Expression mapBitwiseNot(BitwiseNot bitwiseNot) {
        auto integerLiteral = cast(IntegerLiteral) bitwiseNot.inner;
        if (integerLiteral) {
            return new IntegerLiteral(~integerLiteral.getValue());
        }
        return bitwiseNot;
    }

    public override Expression mapExponent(Exponent exponent) {
        return reduceBinaryArithmetic!"^^"(exponent);
    }

    public override Expression mapMultiply(Multiply multiply) {
        if (multiply.operator == "*") {
            return reduceBinaryArithmetic!"*"(multiply);
        }
        if (multiply.operator == "/") {
            return reduceBinaryArithmetic!"/"(multiply);
        }
        if (multiply.operator == "%") {
            return reduceBinaryArithmetic!"%"(multiply);
        }
        throw new Exception("Not a multiply operator: " ~ multiply.operator.toString());
    }

    public override Expression mapAdd(Add add) {
        if (add.operator == "+") {
            return reduceBinaryArithmetic!"+"(add);
        }
        if (add.operator == "-") {
            return reduceBinaryArithmetic!"-"(add);
        }
        throw new Exception("Not an add operator: " ~ add.operator.toString());
    }

    public override Expression mapShift(Shift shift) {
        if (shift.operator == "<<") {
            return reduceBinaryLogic!"<<"(shift);
        }
        if (shift.operator == ">>") {
            return reduceBinaryLogic!">>"(shift);
        }
        if (shift.operator == ">>>") {
            return reduceBinaryLogic!">>>"(shift);
        }
        throw new Exception("Not a shift operator: " ~ shift.operator.toString());
    }

    public override Expression mapBitwiseAnd(BitwiseAnd bitwiseAnd) {
        return reduceBinaryLogic!"&"(bitwiseAnd);
    }

    public override Expression mapBitwiseXor(BitwiseXor bitwiseXor) {
        return reduceBinaryLogic!"^"(bitwiseXor);
    }

    public override Expression mapBitwiseOr(BitwiseOr bitwiseOr) {
        return reduceBinaryLogic!"|"(bitwiseOr);
    }
}

private Expression reduceBinaryArithmetic(string op, Binary)(Binary arithmetic) {
    auto integerLiteralLeft = cast(IntegerLiteral) arithmetic.left;
    if (integerLiteralLeft) {
        auto integerLiteralRight = cast(IntegerLiteral) arithmetic.right;
        if (integerLiteralRight) {
            mixin("return new IntegerLiteral(integerLiteralLeft.getValue() " ~ op ~ " integerLiteralRight.getValue());");
        }
        auto floatLiteralRight = cast(FloatLiteral) arithmetic.right;
        if (floatLiteralRight) {
            mixin("return new FloatLiteral(integerLiteralLeft.getValue() " ~ op ~ " floatLiteralRight.getValue());");
        }
    }
    auto floatLiteralLeft = cast(FloatLiteral) arithmetic.left;
    if (floatLiteralLeft) {
        auto integerLiteralRight = cast(IntegerLiteral) arithmetic.right;
        if (integerLiteralRight) {
            mixin("return new FloatLiteral(floatLiteralLeft.getValue() " ~ op ~ " integerLiteralRight.getValue());");
        }
        auto floatLiteralRight = cast(FloatLiteral) arithmetic.right;
        if (floatLiteralRight) {
            mixin("return new FloatLiteral(floatLiteralLeft.getValue() " ~ op ~ " floatLiteralRight.getValue());");
        }
    }
    return arithmetic;
}

private Expression reduceBinaryLogic(string op, Binary)(Binary logic) {
    auto literalLeft = cast(IntegerLiteral) logic.left;
    auto literalRight = cast(IntegerLiteral) logic.right;
    if (literalLeft && literalRight) {
        mixin("return new IntegerLiteral(literalLeft.getValue() " ~ op ~ " literalRight.getValue());");
    }
    return logic;
}
