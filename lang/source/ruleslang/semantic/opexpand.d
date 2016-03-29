module ruleslang.semantic.opexpand;

import std.conv : to;

import ruleslang.syntax.token;
import ruleslang.syntax.ast.type;
import ruleslang.syntax.ast.expression;
import ruleslang.syntax.ast.statement;
import ruleslang.syntax.ast.mapper;

public Statement expandOperators(Statement target) {
    return target.accept(new OperatorExpander()).accept(new OperatorRewriter());
}

private class OperatorExpander : StatementMapper {
    public override Statement mapAssignment(Assignment assignment) {
        switch (assignment.operator.getSource()) {
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
            default:
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
}

private class OperatorRewriter : StatementMapper {
    public override Expression mapExponent(Exponent exponent) {
        auto stdPow = new NameReference([
            new Identifier("std", exponent.operator.start, exponent.operator.end),
            new Identifier("math", exponent.operator.start, exponent.operator.end),
            new Identifier("pow", exponent.operator.start, exponent.operator.end)
        ]);
        return new FunctionCall(stdPow, [exponent.left, exponent.right], exponent.start, exponent.end);
    }

    public override Expression mapRange(Range range) {
        auto stdRange = new NamedType(
            [
                new Identifier("std", range.start, range.end),
                new Identifier("range", range.start, range.end),
                new Identifier("Range", range.start, range.end)
            ],
            new Expression[0],
            range.end
        );
        auto literal = new CompositeLiteral([
            new LabeledExpression(null, range.left),
            new LabeledExpression(null, range.right),
        ], range.start, range.end);
        return new Initializer(stdRange, literal);
    }

    public override Expression mapInfix(Infix infix) {
        return new FunctionCall(new NameReference([infix.operator]), [infix.left, infix.right], infix.start, infix.end);
    }
}

private Statement expandAssignment(Bin, BinOp, string op)(Assignment assignment) {
    auto value = new Bin(assignment.target, assignment.value, new BinOp(op.to!dstring, assignment.operator.start));
    return new Assignment(assignment.target, value, new AssignmentOperator("=", assignment.operator.start));
}
