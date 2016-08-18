module ruleslang.syntax.ast.statement;

import std.format : format;

import ruleslang.syntax.source;
import ruleslang.syntax.token;
import ruleslang.syntax.ast.expression;
import ruleslang.syntax.ast.mapper;
import ruleslang.util;

public interface Statement : SourceIndexed {
    public Statement map(StatementMapper mapper);
    public string toString();
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

    @property public override size_t start() {
        return _target.start;
    }

    @property public override size_t end() {
        return _value.end;
    }

    public override Statement map(StatementMapper mapper) {
        _target = _target.map(mapper);
        _value = _value.map(mapper);
        return mapper.mapAssignment(this);
    }

    public override string toString() {
        return format("Assignment(%s %s %s)", _target.toString(), _operator.getSource(), _value.toString());
    }
}
