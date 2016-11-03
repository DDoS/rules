module ruleslang.syntax.parser.rule;

import std.format : format;

import ruleslang.syntax.source;
import ruleslang.syntax.token;
import ruleslang.syntax.tokenizer;
import ruleslang.syntax.ast.statement;
import ruleslang.syntax.ast.rule;
import ruleslang.syntax.parser.type;
import ruleslang.syntax.parser.statement;
import ruleslang.util;

private alias parseWhenDefinition = parseRulePartDefinition!WhenDefinition;
private alias parseThenDefinition = parseRulePartDefinition!ThenDefinition;

private RulePartDefinition parseRulePartDefinition(RulePartDefinition)(Tokenizer tokens) {
    enum keyword = is(RulePartDefinition == WhenDefinition) ? "when" : "then";
    if (tokens.head() != keyword) {
        throw new SourceException("Expected \"" ~ keyword ~ "\"", tokens.head());
    }
    auto start = tokens.head().start;
    tokens.advance();
    // Parse the parameter
    if (tokens.head() != "(") {
        throw new SourceException("Expected '('", tokens.head());
    }
    tokens.advance();
    // Parse the parameter type
    auto type = parseNamedType(tokens);
    if (tokens.head().getKind() != Kind.IDENTIFIER) {
        throw new SourceException("Expected an identifier", tokens.head());
    }
    // Parse the parameter name
    auto name = tokens.head().castOrFail!Identifier();
    tokens.advance();
    if (tokens.head() != ")") {
        throw new SourceException("Expected ')'", tokens.head());
    }
    tokens.advance();
    // Terminate the signature
    if (tokens.head() != ":") {
        throw new SourceException("Expected ':'", tokens.head());
    }
    auto end = tokens.head().end;
    tokens.advance();
    // Get the indentation of the implementation block
    auto blockIndentSpec = getBlockIdentation(tokens);
    // Parse the statements in the block
    auto statements = parseFlowStatements(tokens, blockIndentSpec);
    if (statements.length > 0) {
        end = statements[$ - 1].end;
    }
    return new RulePartDefinition(type, name, statements, start, end);
}

public Statement parseDefinition(Tokenizer tokens, IndentSpec parentIndent = noIndent()) {
    assert (parentIndent.isEmpty());
    switch (tokens.head().getSource()) {
        case "def":
            return parseTypeDefinition(tokens);
        case "let":
        case "var":
            return parseVariableDeclaration(tokens);
        case "func":
            return parseFunctionDefinition(tokens);
        case "when":
            return parseWhenDefinition(tokens);
        case "then":
            return parseThenDefinition(tokens);
        default:
            throw new SourceException("Not a definition", tokens.head());
    }
}

public Rule parseRule(Tokenizer tokens) {
    TypeDefinition[] typeDefinitions;
    VariableDeclaration[] variableDeclarations;
    FunctionDefinition[] functionDefinitions;
    WhenDefinition whenDefinition = null;
    ThenDefinition thenDefinition = null;
    foreach (definition; parseStatements!parseDefinition(tokens)) {
        if (auto typeDef = cast(TypeDefinition) definition) {
            typeDefinitions ~= typeDef;
        } else if (auto varDecl = cast(VariableDeclaration) definition) {
            variableDeclarations ~= varDecl;
        } else if (auto funcDef = cast(FunctionDefinition) definition) {
            functionDefinitions ~= funcDef;
        } else if (auto whenDef = cast(WhenDefinition) definition) {
            if (whenDefinition !is null) {
                throw new SourceException("Cannot have multiple \"when\" definitions", whenDef);
            }
            whenDefinition = whenDef;
        } else if (auto thenDef = cast(ThenDefinition) definition) {
            if (thenDefinition !is null) {
                throw new SourceException("Cannot have multiple \"when\" definitions", thenDef);
            }
            thenDefinition = thenDef;
        } else {
            assert (0);
        }
    }
    return new Rule(typeDefinitions, variableDeclarations, functionDefinitions, whenDefinition, thenDefinition);
}
