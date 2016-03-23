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
    private Expression _target;
    private Expression _value;
    private AssignmentOperator _operator;

    public this(Expression target, Expression value, AssignmentOperator operator) {
        _target = target;
        _value = value;
        _operator = operator;
    }

    @property public Expression target() {
        return _target;
    }

    @property public Expression value() {
        return _value;
    }

    @property public AssignmentOperator operator() {
        return _operator;
    }

    public override Statement accept(StatementMapper mapper) {
        _target = _target.accept(mapper);
        _value = _value.accept(mapper);
        return mapper.mapAssignment(this);
    }

    public override string toString() {
        return format("Assignment(%s %s %s)", _target.toString(), _operator.getSource(), _value.toString());
    }
}
