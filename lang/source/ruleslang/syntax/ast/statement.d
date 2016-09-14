module ruleslang.syntax.ast.statement;

import std.format : format;

import ruleslang.syntax.source;
import ruleslang.syntax.token;
import ruleslang.syntax.ast.type;
import ruleslang.syntax.ast.expression;
import ruleslang.syntax.ast.mapper;
import ruleslang.semantic.tree;
import ruleslang.semantic.context;
import ruleslang.semantic.interpret;
import ruleslang.util;

public interface Statement {
    @property public size_t start();
    @property public size_t end();
    @property public void start(size_t start);
    @property public void end(size_t end);
    public Statement map(StatementMapper mapper);
    public immutable(Node) interpret(Context context);
    public string toString();
}

public class TypeDefinition : Statement {
    private Identifier _name;
    private TypeAst _type;

    public this(Identifier name, TypeAst type, size_t start) {
        _name = name;
        _type = type;
        _start = start;
        _end = type.end;
    }

    @property public Identifier name() {
        return _name;
    }

    @property public TypeAst type() {
        return _type;
    }

    mixin sourceIndexFields;

    public override Statement map(StatementMapper mapper) {
        _type = _type.map(mapper);
        return mapper.mapTypeDefinition(this);
    }

    public override immutable(Node) interpret(Context context) {
        return Interpreter.INSTANCE.interpretTypeDefinition(context, this);
    }

    public override string toString() {
        return format("TypeDefinition(def %s: %s)", _name.getSource(), _type.toString());
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
        _start = target.start;
        _end = value.end;
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

    mixin sourceIndexFields;

    public override Statement map(StatementMapper mapper) {
        _target = _target.map(mapper);
        _value = _value.map(mapper);
        return mapper.mapAssignment(this);
    }

    public override immutable(Node) interpret(Context context) {
        return Interpreter.INSTANCE.interpretAssignment(context, this);
    }

    public override string toString() {
        return format("Assignment(%s %s %s)", _target.toString(), _operator.getSource(), _value.toString());
    }
}
