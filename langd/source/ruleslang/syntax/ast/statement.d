module ruleslang.syntax.ast.statement;

import std.format;

import ruleslang.syntax.token;
import ruleslang.syntax.ast.expression;

public interface Statement {
    public string toString();
}

public class InitializerAssignment : Expression {
    private Expression target;
    private CompositeLiteral literal;

    public this(Expression target, CompositeLiteral literal) {
        this.target = target;
        this.literal = literal;
    }

    public override string toString() {
        return format("InitializerAssignment(%s = %s)", target.toString(), literal.toString());
    }
}

public class Assignment : Expression {
    private Expression target;
    private Expression value;
    private AssignmentOperator operator;

    public this(Expression target, Expression value, AssignmentOperator operator) {
        this.target = target;
        this.value = value;
        this.operator = operator;
    }

    public override string toString() {
        return format("Assignment(%s %s %s)", target.toString(), operator.toString(), value.toString());
    }
}
