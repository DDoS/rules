module ruleslang.syntax.ast.statement;

import std.format : format;
import std.conv : to;
import std.uni : toLower;

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

public class VariableDeclaration : Statement {
    public enum Kind {
        LET, VAR
    }

    VariableDeclaration.Kind _kind;
    private NamedTypeAst _type;
    private Identifier _name;
    private Expression _value;

    public this(VariableDeclaration.Kind kind, NamedTypeAst type, Identifier name, size_t start) {
        this(kind, type, name, null, start);
    }

    public this(VariableDeclaration.Kind kind, Identifier name, Expression value, size_t start) {
        this(kind, null, name, value, start);
    }

    public this(VariableDeclaration.Kind kind, NamedTypeAst type, Identifier name, Expression value, size_t start) {
        assert (type !is null || value !is null);
        _kind = kind;
        _type = type;
        _name = name;
        _value = value;
        _start = start;
        _end = value is null ? name.end : value.end;
    }

    @property public VariableDeclaration.Kind kind() {
        return _kind;
    }

    @property public NamedTypeAst type() {
        return _type;
    }

    @property public Identifier name() {
        return _name;
    }

    @property public Expression value() {
        return _value;
    }

    mixin sourceIndexFields;

    public override Statement map(StatementMapper mapper) {
        if (_type !is null) {
            _type = _type.map(mapper).castOrFail!NamedTypeAst();
        }
        if (_value !is null) {
            _value = _value.map(mapper);
        }
        return mapper.mapVariableDeclaration(this);
    }

    public override immutable(Node) interpret(Context context) {
        return Interpreter.INSTANCE.interpretVariableDeclaration(context, this);
    }

    public override string toString() {
        auto kindString = _kind.to!string().toLower();
        if (_type is null) {
            return format("VariableDeclaration(%s %s = %s)", kindString, _name.getSource(), _value.toString());
        }
        if (_value is null) {
            return format("VariableDeclaration(%s %s %s)", kindString, _type.toString(), _name.getSource());
        }
        return format("VariableDeclaration(%s %s %s = %s)", kindString, _type.toString(), _name.getSource(), _value.toString());
    }
}

public class Assignment : Statement {
    private AssignableExpression _target;
    private Expression _value;
    private AssignmentOperator _operator;

    public this(AssignableExpression target, Expression value, AssignmentOperator operator) {
        _target = target;
        _value = value;
        _operator = operator;
        _start = target.start;
        _end = value.end;
    }

    @property public AssignableExpression target() {
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
        _target = _target.map(mapper).castOrFail!AssignableExpression();
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

public class ConditionalStatement : Statement {
    public struct Block {
        private Expression _condition;
        private Statement[] _statements;

        public this(Expression condition, Statement[] statements, size_t start, size_t end) {
            _condition = condition;
            _statements = statements;
            _start = start;
            _end = end;
        }

        mixin sourceIndexFields;

        @property public Expression condition() {
            return _condition;
        }

        @property public Statement[] statements() {
            return _statements;
        }

        private void map(StatementMapper mapper) {
            _condition = _condition.map(mapper);
            foreach (i, statement; _statements) {
                _statements[i] = statement.map(mapper);
            }
        }

        public string toString() {
            return format("if %s: %s", _condition.toString(), _statements.join!"; "());
        }
    }

    private Block[] _conditionBlocks;
    private Statement[] _falseStatements;

    public this(Block[] conditionBlocks, Statement[] falseStatements, size_t end) {
        assert (conditionBlocks.length > 0);
        _conditionBlocks = conditionBlocks;
        _falseStatements = falseStatements;
        _start = conditionBlocks[0].start;
        _end = end;
    }

    @property public Block[] conditionBlocks() {
        return _conditionBlocks;
    }

    @property public Statement[] falseStatements() {
        return _falseStatements;
    }

    mixin sourceIndexFields;

    public override Statement map(StatementMapper mapper) {
        foreach (i; 0 .. _conditionBlocks.length) {
            _conditionBlocks[i].map(mapper);
        }
        foreach (i, statement; _falseStatements) {
            _falseStatements[i] = statement.map(mapper);
        }
        return mapper.mapConditionalStatement(this);
    }

    public override immutable(Node) interpret(Context context) {
        return Interpreter.INSTANCE.interpretConditionalStatement(context, this);
    }

    public override string toString() {
        auto falseBlockString = falseStatements.length > 0 ? format("; else: %s", _falseStatements.join!"; "()) : "";
        return format("ConditionalStatement(%s%s)", _conditionBlocks.join!"; else "(), falseBlockString);
    }
}
