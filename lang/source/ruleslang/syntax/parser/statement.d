module ruleslang.syntax.parser.statement;

import std.format : format;

import ruleslang.syntax.dchars;
import ruleslang.syntax.source;
import ruleslang.syntax.token;
import ruleslang.syntax.tokenizer;
import ruleslang.syntax.ast.type;
import ruleslang.syntax.ast.expression;
import ruleslang.syntax.ast.statement;
import ruleslang.syntax.parser.type;
import ruleslang.syntax.parser.expression;
import ruleslang.util;

private struct IndentSpec {
    private dchar w;
    private uint count;

    private this(dchar w, uint count) {
        this.w = w;
        this.count = count;
    }

    private bool validate(Indentation indentation) {
        if (indentation.getSource().length != count) {
            return false;
        }
        foreach (c; indentation.getSource()) {
            if (c != w) {
                return false;
            }
        }
        return true;
    }
}

private IndentSpec* noIndentation() {
    return new IndentSpec(' ', 0);
}

private TypeDefinition parseTypeDefinition(Tokenizer tokens) {
    if (tokens.head() != "def") {
        throw new SourceException("Expected \"def\"", tokens.head());
    }
    auto start = tokens.head().start;
    tokens.advance();
    if (tokens.head().getKind() != Kind.IDENTIFIER) {
        throw new SourceException("Expected an identifier", tokens.head());
    }
    auto name = tokens.head().castOrFail!Identifier();
    tokens.advance();
    if (tokens.head() != ":") {
        throw new SourceException("Expected ':'", tokens.head());
    }
    tokens.advance();
    auto type = parseType(tokens);
    return new TypeDefinition(name, type, start);
}

private VariableDeclaration parseVariableDeclaration(Tokenizer tokens) {
    // Try to parse "let" or "var" first
    VariableDeclaration.Kind kind;
    if (tokens.head() == "let") {
        kind = VariableDeclaration.Kind.LET;
    } else if (tokens.head() == "var") {
        kind = VariableDeclaration.Kind.VAR;
    } else {
        throw new SourceException("Expected \"let\" or \"var\"", tokens.head());
    }
    auto start = tokens.head().start;
    tokens.advance();
    // Now we can parse an optional named type, which starts with an identifier
    tokens.savePosition();
    auto type = parseNamedType(tokens);
    auto furthestPosition = tokens.head().start;
    // We need another identifier for the variable name which comes after
    if (tokens.head().getKind() == Kind.IDENTIFIER) {
        tokens.discardPosition();
    } else {
        // If we don't have one then back off: the identifier we parsed as a type is the name
        type = null;
        tokens.restorePosition();
    }
    // Now parse the identifier for the name
    if (tokens.head().getKind() != Kind.IDENTIFIER) {
        throw new SourceException("Expected an identifier", tokens.head());
    }
    auto name = tokens.head().castOrFail!Identifier();
    tokens.advance();
    // If we don't have an "=" operator then there isn't any value
    if (tokens.head() != "=") {
        // In this case having a named type is mandatory, not having one means the name is missing
        if (type is null) {
            throw new SourceException("Expected an identifier", furthestPosition);
        }
        return new VariableDeclaration(kind, type, name, start);
    }
    tokens.advance();
    // Otherwise parse and expression for the value
    auto value = parseExpression(tokens);
    return new VariableDeclaration(kind, type, name, value, start);
}

private Statement parseAssigmnentOrFunctionCall(Tokenizer tokens) {
    auto access = parseAccess(tokens);
    auto call = cast(FunctionCall) access;
    if (call !is null) {
        return call;
    }
    auto reference = cast(Reference) access;
    if (reference is null) {
        throw new SourceException("Not a reference expression", access);
    }
    if (tokens.head().getKind() != Kind.ASSIGNMENT_OPERATOR) {
        throw new SourceException("Expected an assignment operator", tokens.head());
    }
    auto operator = tokens.head().castOrFail!AssignmentOperator();
    tokens.advance();
    return new Assignment(access, parseExpression(tokens), operator);
}

public Statement parseStatement(Tokenizer tokens) {
    if (tokens.head() == "def") {
        return parseTypeDefinition(tokens);
    }
    if (tokens.head() == "let" || tokens.head() == "var") {
        return parseVariableDeclaration(tokens);
    }
    return parseAssigmnentOrFunctionCall(tokens);
}

public Statement[] parseStatements(Tokenizer tokens) {
    return parseStatements(tokens, noIndentation());
}

private Statement[] parseStatements(Tokenizer tokens, IndentSpec* indentSpec) {
    Statement[] statements = [];
    auto nextIndentIgnored = false;
    while (tokens.has()) {
        Indentation lastIndent = null;
        // Consume indentation preceding the statement
        while (tokens.head().getKind() == Kind.INDENTATION) {
            lastIndent = tokens.head().castOrFail!Indentation();
            tokens.advance();
        }
        // Indentation could precede end of source
        if (!tokens.has()) {
            break;
        }
        // Only the last indentation before the statement matters
        if (!nextIndentIgnored && (lastIndent is null || !indentSpec.validate(lastIndent))) {
            auto problem = lastIndent is null ? tokens.head() : lastIndent;
            throw new SourceException(
                format("Expected %d of '%s' as indentation", indentSpec.count, indentSpec.w.escapeChar()),
                problem
            );
        }
        nextIndentIgnored = false;
        // Parse the statement
        statements ~= parseStatement(tokens);
        // Check for termination
        if (tokens.head().getKind() == Kind.TERMINATOR) {
            tokens.advance();
            // Can ignore indentation for the next statement if on the same line
            nextIndentIgnored = true;
            continue;
        }
        if (tokens.head().getKind() == Kind.INDENTATION) {
            // Indentation marks a new statement, so the end of the current one
            continue;
        }
        if (!tokens.has()) {
            // Nothing else to parse (EOF is a valid termination)
            break;
        }
        throw new SourceException("Expected end of statement", tokens.head());
    }
    return statements;
}
