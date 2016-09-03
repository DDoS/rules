module ruleslang.semantic.opexpand;

import std.conv : to;

import ruleslang.syntax.token;
import ruleslang.syntax.ast.type;
import ruleslang.syntax.ast.expression;
import ruleslang.syntax.ast.statement;
import ruleslang.syntax.ast.mapper;
import ruleslang.semantic.symbol;

public Expression expandOperators(Expression target) {
    return target.map(new OperatorExpander()).map(new OperatorConverter());
}

public Statement expandOperators(Statement target) {
    return target.map(new OperatorExpander()).map(new OperatorConverter());
}

private class OperatorExpander : StatementMapper {
    public override Statement mapAssignment(Assignment assignment) {
        final switch (assignment.operator.getSource()) {
            case "**=":
                return expandAssignment!(Exponent, ExponentOperator, "**")(assignment);
            case "*=":
                return expandAssignment!(Multiply, MultiplyOperator, "*")(assignment);
            case "/=":
                return expandAssignment!(Multiply, MultiplyOperator, "/")(assignment);
            case "%=":
                return expandAssignment!(Multiply, MultiplyOperator, "%")(assignment);
            case "+=":
                return expandAssignment!(Add, AddOperator, "+")(assignment);
            case "-=":
                return expandAssignment!(Add, AddOperator, "-")(assignment);
            case "<<=":
                return expandAssignment!(Shift, ShiftOperator, "<<")(assignment);
            case ">>=":
                return expandAssignment!(Shift, ShiftOperator, ">>")(assignment);
            case ">>>=":
                return expandAssignment!(Shift, ShiftOperator, ">>>")(assignment);
            case "&=":
                return expandAssignment!(BitwiseAnd, BitwiseAndOperator, "&")(assignment);
            case "^=":
                return expandAssignment!(BitwiseXor, BitwiseXorOperator, "^")(assignment);
            case "|=":
                return expandAssignment!(BitwiseOr, BitwiseOrOperator, "|")(assignment);
            case "&&=":
                return expandAssignment!(LogicalAnd, LogicalAndOperator, "&&")(assignment);
            case "^^=":
                return expandAssignment!(LogicalXor, LogicalXorOperator, "^^")(assignment);
            case "||=":
                return expandAssignment!(LogicalOr, LogicalOrOperator, "||")(assignment);
            case "~=":
                return expandAssignment!(Concatenate, ConcatenateOperator, "~")(assignment);
            case "=":
                return assignment;
        }
    }

    public override Expression mapCompare(Compare compare) {
        Expression compareChain = null;
        foreach (i, operator; compare.valueOperators) {
            auto element = new ValueCompare(compare.values[i], compare.values[i + 1], operator);
            if (compareChain is null) {
                compareChain = element;
            } else {
                compareChain = new LogicalAnd(compareChain, element, new LogicalAndOperator("&&"d, operator.start));
            }
        }
        if (compare.type !is null) {
            auto element = new TypeCompare(compare.values[$ - 1], compare.type, compare.typeOperator);
            if (compareChain is null) {
                compareChain = element;
            } else {
                compareChain = new LogicalAnd(compareChain, element, new LogicalAndOperator("&&"d, compare.typeOperator.start));
            }
        }
        return compareChain;
    }

    public override Expression mapInfix(Infix infix) {
        return new FunctionCall(new NameReference([infix.operator]), [infix.left, infix.right], infix.start, infix.end);
    }

    private static Statement expandAssignment(Bin, BinOp, string op)(Assignment assignment) {
        auto value = new Bin(assignment.target, assignment.value, new BinOp(op, assignment.operator.start));
        return new Assignment(assignment.target, value, new AssignmentOperator("=", assignment.operator.start));
    }
}

private class OperatorConverter : StatementMapper {
    public override Expression mapSign(Sign expression) {
        // Don't convert signs for signed decimal integer literals
        // because they are actually part of the literal
        auto integer = cast(SignedIntegerLiteral) expression.inner;
        if (integer && integer.radix == 10) {
            return expression;
        }
        auto op = expression.operator;
        mixin(genConversionUnary!"+");
        mixin(genConversionUnary!"-");
        assert(0);
    }

    public override Expression mapLogicalNot(LogicalNot expression) {
        auto op = expression.operator;
        mixin(genConversionUnary!"!");
        assert(0);
    }

    public override Expression mapBitwiseNot(BitwiseNot expression) {
        auto op = expression.operator;
        mixin(genConversionUnary!"~");
        assert(0);
    }

    public override Expression mapExponent(Exponent expression) {
        auto op = expression.operator;
        mixin(genConversionBinary!"**");
        assert(0);
    }

    public override Expression mapMultiply(Multiply expression) {
        auto op = expression.operator;
        mixin(genConversionBinary!"*");
        mixin(genConversionBinary!"/");
        mixin(genConversionBinary!"%");
        assert(0);
    }

    public override Expression mapAdd(Add expression) {
        auto op = expression.operator;
        mixin(genConversionBinary!"+");
        mixin(genConversionBinary!"-");
        assert(0);
    }

    public override Expression mapShift(Shift expression) {
        auto op = expression.operator;
        mixin(genConversionBinary!"<<");
        mixin(genConversionBinary!">>");
        mixin(genConversionBinary!">>>");
        assert(0);
    }

    public override Expression mapValueCompare(ValueCompare expression) {
        auto op = expression.operator;
        if (op == "===" || op == "!==") {
            return expression;
        }
        mixin(genConversionBinary!"==");
        mixin(genConversionBinary!"!=");
        mixin(genConversionBinary!"<");
        mixin(genConversionBinary!">");
        mixin(genConversionBinary!"<=");
        mixin(genConversionBinary!">=");
        assert(0);
    }

    public override Expression mapBitwiseAnd(BitwiseAnd expression) {
        auto op = expression.operator;
        mixin(genConversionBinary!"&");
        assert(0);
    }

    public override Expression mapBitwiseXor(BitwiseXor expression) {
        auto op = expression.operator;
        mixin(genConversionBinary!"^");
        assert(0);
    }

    public override Expression mapBitwiseOr(BitwiseOr expression) {
        auto op = expression.operator;
        mixin(genConversionBinary!"|");
        assert(0);
    }

    public override Expression mapLogicalAnd(LogicalAnd expression) {
        auto op = expression.operator;
        mixin(genConversionBinary!"&&");
        assert(0);
    }

    public override Expression mapLogicalXor(LogicalXor expression) {
        auto op = expression.operator;
        mixin(genConversionBinary!"^^");
        assert(0);
    }

    public override Expression mapLogicalOr(LogicalOr expression) {
        auto op = expression.operator;
        mixin(genConversionBinary!"||");
        assert(0);
    }

    public override Expression mapConcatenate(Concatenate expression) {
        auto op = expression.operator;
        mixin(genConversionBinary!"~");
        assert(0);
    }

    public override Expression mapRange(Range expression) {
        auto op = expression.operator;
        mixin(genConversionBinary!"..");
        assert(0);
    }

    private alias genConversionUnary(string op) = genConversion!(op, false);

    private alias genConversionBinary(string op) = genConversion!(op, true);

    private static string genConversion(string op, bool binary)() {
        string args = binary ? "expression.left, expression.right" : "expression.inner";
        string conv = binary ? "BINARY_OPERATOR_TO_FUNCTION" : "UNARY_OPERATOR_TO_FUNCTION";
        return `
        if (op == "` ~ op ~ `") {
            return new FunctionCall(
                new NameReference([new Identifier(` ~ conv ~ `[op.getSource()], op.start, op.end)]),
                [` ~ args ~ `], expression.start, expression.end
            );
        }
        `;
    }
}
