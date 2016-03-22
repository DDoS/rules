module ruleslang.syntax.ast.statement;

import std.format;

import ruleslang.syntax.token;
import ruleslang.syntax.ast.expression;
import ruleslang.syntax.ast.mapper;

public interface Statement {
    public Statement accept(StatementMapper mapper);
    public string toString();
}

public class InitializerAssignment : Statement {
    private Expression target;
    private CompositeLiteral literal;

    public this(Expression target, CompositeLiteral literal) {
        this.target = target;
        this.literal = literal;
    }

    public override Statement accept(StatementMapper mapper) {
        target = target.accept(mapper);
        literal = cast(CompositeLiteral) literal.accept(mapper);
        return mapper.mapInitializerAssignment(this);
    }

    public override string toString() {
        return format("InitializerAssignment(%s = %s)", target.toString(), literal.toString());
    }
}

public class Assignment : Statement {
    private Expression target;
    private Expression value;
    private AssignmentOperator operator;

    public this(Expression target, Expression value, AssignmentOperator operator) {
        this.target = target;
        this.value = value;
        this.operator = operator;
    }

    public override Statement accept(StatementMapper mapper) {
        target = target.accept(mapper);
        value = value.accept(mapper);
        return mapper.mapAssignment(this);
    }

    public override string toString() {
        return format("Assignment(%s %s %s)", target.toString(), operator.getSource(), value.toString());
    }
}
