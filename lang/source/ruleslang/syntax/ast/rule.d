module ruleslang.syntax.ast.rule;

import std.format : format;

import ruleslang.syntax.source;
import ruleslang.syntax.token;
import ruleslang.syntax.ast.type;
import ruleslang.syntax.ast.statement;
import ruleslang.util;

public alias WhenDefinition = RulePartDefinition!false;
public alias ThenDefinition = RulePartDefinition!true;

private template RulePartDefinition(bool then) {
    public class RulePartDefinition {
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

    public this(TypeDefinition[] typeDefinitions, VariableDeclaration[] variableDeclarations,
            FunctionDefinition[] functionDefinitions) {
        _typeDefinitions = typeDefinitions;
        _variableDeclarations = variableDeclarations;
        _functionDefinitions = functionDefinitions;
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
}
