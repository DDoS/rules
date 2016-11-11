module ruleslang.syntax.ast.rule;

import std.format : format;

import ruleslang.syntax.source;
import ruleslang.syntax.token;
import ruleslang.syntax.ast.type;
import ruleslang.syntax.ast.statement;
import ruleslang.syntax.ast.mapper;
import ruleslang.semantic.tree;
import ruleslang.semantic.context;
import ruleslang.semantic.interpret;
import ruleslang.util;

public alias WhenDefinition = RulePartDefinition!false;
public alias ThenDefinition = RulePartDefinition!true;

private template RulePartDefinition(bool then) {
    public class RulePartDefinition : Statement {
        private NamedTypeAst _type;
        private Identifier _name;
        private Statement[] _statements;

        public this(NamedTypeAst type, Identifier name, Statement[] statements, size_t start, size_t end) {
            _type = type;
            _name = name;
            _statements = statements;
            _start = start;
            _end = end;
        }

        @property public NamedTypeAst type() {
            return _type;
        }

        @property public Identifier name() {
            return _name;
        }

        @property public Statement[] statements() {
            return _statements;
        }

        mixin sourceIndexFields;

        public override Statement map(StatementMapper mapper) {
            _type = _type.map(mapper).castOrFail!NamedTypeAst();
            foreach (i, statement; _statements) {
                _statements[i] = statement.map(mapper);
            }
            static if (then) {
                return mapper.mapThenDefinition(this);
            } else {
                return mapper.mapWhenDefinition(this);
            }
        }

        public override immutable(FlowNode) interpret(Context context) {
            static if (then) {
                return Interpreter.INSTANCE.interpretThenDefinition(context, this);
            } else {
                return Interpreter.INSTANCE.interpretWhenDefinition(context, this);
            }
        }

        public override string toString() {
            enum formatString = then ? "ThenDefinition(then (%s %s): %s)" : "WhenDefinition(when (%s %s): %s)";
            return format(formatString, _type.toString(), _name.getSource(), _statements.join!"; "());
        }
    }
}

public class Rule {
    private TypeDefinition[] _typeDefinitions;
    private VariableDeclaration[] _variableDeclarations;
    private FunctionDefinition[] _functionDefinitions;
    private WhenDefinition _whenDefinition;
    private ThenDefinition _thenDefinition;

    public this(TypeDefinition[] typeDefinitions, VariableDeclaration[] variableDeclarations,
            FunctionDefinition[] functionDefinitions, WhenDefinition whenDefinition, ThenDefinition thenDefinition) {
        _typeDefinitions = typeDefinitions;
        _variableDeclarations = variableDeclarations;
        _functionDefinitions = functionDefinitions;
        _whenDefinition = whenDefinition;
        _thenDefinition = thenDefinition;
    }

    @property public TypeDefinition[] typeDefinitions() {
        return _typeDefinitions;
    }

    @property public VariableDeclaration[] variableDeclarations() {
        return _variableDeclarations;
    }

    @property public FunctionDefinition[] functionDefinitions() {
        return _functionDefinitions;
    }

    @property public WhenDefinition whenDefinition() {
        return _whenDefinition;
    }

    @property public ThenDefinition thenDefinition() {
        return _thenDefinition;
    }

    public Rule map(RuleMapper mapper) {
        foreach (i, typeDef; _typeDefinitions) {
            _typeDefinitions[i] = typeDef.map(mapper).castOrFail!TypeDefinition();
        }
        foreach (i, varDecl; _variableDeclarations) {
            _variableDeclarations[i] = varDecl.map(mapper).castOrFail!VariableDeclaration();
        }
        foreach (i, funcDef; _functionDefinitions) {
            _functionDefinitions[i] = funcDef.map(mapper).castOrFail!FunctionDefinition();
        }
        if (whenDefinition !is null) {
            _whenDefinition = _whenDefinition.map(mapper).castOrFail!WhenDefinition();
        }
        if (thenDefinition !is null) {
            _thenDefinition = _thenDefinition.map(mapper).castOrFail!ThenDefinition();
        }
        return mapper.mapRule(this);
    }

    public immutable(Node) interpret(Context context) {
        return Interpreter.INSTANCE.interpretRule(context, this);
    }

    public override string toString() {
        string[] stmts;
        foreach (typeDef; _typeDefinitions) {
            stmts ~= typeDef.toString();
        }
        foreach (varDecl; _variableDeclarations) {
            stmts ~= varDecl.toString();
        }
        foreach (funcDef; _functionDefinitions) {
            stmts ~= funcDef.toString();
        }
        if (whenDefinition !is null) {
            stmts ~= whenDefinition.toString();
        }
        if (thenDefinition !is null) {
            stmts ~= thenDefinition.toString();
        }
        return format("Rule(%s)", stmts.join!"; "());
    }
}
