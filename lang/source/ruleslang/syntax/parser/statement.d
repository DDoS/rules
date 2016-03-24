module ruleslang.syntax.parser.statement;

import std.format : format;

import ruleslang.syntax.dchars;
import ruleslang.syntax.source;
import ruleslang.syntax.token;
import ruleslang.syntax.tokenizer;
import ruleslang.syntax.ast.expression;
import ruleslang.syntax.ast.statement;
import ruleslang.syntax.parser.expression;

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
    auto operator = cast(AssignmentOperator) tokens.head();
    tokens.advance();
    if (operator == "=" && tokens.head() == "{") {
        return new InitializerAssignment(access, parseCompositeLiteral(tokens));
    }
    return new Assignment(access, parseExpression(tokens), operator);
}

public Statement parseStatement(Tokenizer tokens) {
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
            lastIndent = cast(Indentation) tokens.head();
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
            // Nothing else to parse
            break;
        }
        throw new SourceException("Expected end of statement", tokens.head());
    }
    return statements;
}
