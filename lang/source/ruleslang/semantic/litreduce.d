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
}
