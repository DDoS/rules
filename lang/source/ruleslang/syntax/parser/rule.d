module ruleslang.syntax.parser.rule;

import std.format : format;

import ruleslang.syntax.source;
import ruleslang.syntax.token;
import ruleslang.syntax.tokenizer;
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
    auto statements = parseStatements(tokens, blockIndentSpec);
    if (statements.length > 0) {
        end = statements[$ - 1].end;
    }
    return new RulePartDefinition(type, name, statements, start, end);
}

public string parseRule(Tokenizer tokens) {
    while (tokens.head().getKind() == Kind.INDENTATION) {
        auto indentation = tokens.head().castOrFail!Indentation();
        if (indentation.getSource().length > 0) {
            throw new SourceException("Expected no indentation", indentation);
        }
        tokens.advance();
    }
    switch (tokens.head().getSource()) {
        case "when":
            return parseWhenDefinition(tokens).toString();
        case "then":
            return parseThenDefinition(tokens).toString();
        default:
            assert (0);
    }
}
