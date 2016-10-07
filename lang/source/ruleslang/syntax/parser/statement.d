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
    private size_t count;
    private char w;
    private bool nextIndentIgnored = false;

    private this(char w, size_t count) {
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

    private IndentSpec opBinary(string op)(Indentation indentation) {
        static if (op == "+") {
            void mixedError(char w, char c) {
                throw new SourceException(format("Mixed indentation: should be '%s', but got '%s'",
                        this.w.escapeChar(), c.escapeChar()), indentation);
            }
            auto source = indentation.getSource();
            if (source.length <= 0) {
                throw new SourceException("Expected some indentation", indentation);
            }
            char w = source[0];
            if (count > 0 && this.w != w) {
                mixedError(this.w, w);
            }
            foreach (c; source) {
                if (w != c) {
                    mixedError(w, c);
                }
            }
            return IndentSpec(w, count + source.length);
        } else {
            static assert(0);
        }
    }

    private string toString() {
        if (count == 0) {
            return "no indentation";
        }
        return format("%d of '%s' of indentation", count, w.escapeChar());
    }
}

private IndentSpec noIndent() {
    return IndentSpec(' ', 0);
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

private Statement parseAssigmnentOrFunctionCall(Tokenizer tokens) {
    auto access = parseAccess(tokens);
    auto call = cast(FunctionCall) access;
    if (call !is null) {
        return new FunctionCallStatement(call);
    }
    auto reference = cast(AssignableExpression) access;
    if (reference is null) {
        throw new SourceException("Not an assignable expression", access);
    }
    if (tokens.head().getKind() != Kind.ASSIGNMENT_OPERATOR) {
        throw new SourceException("Expected an assignment operator", tokens.head());
    }
    auto operator = tokens.head().castOrFail!AssignmentOperator();
    tokens.advance();
    return new Assignment(reference, parseExpression(tokens), operator);
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

private ConditionalStatement parseConditionalStatement(Tokenizer tokens, IndentSpec indentSpec = noIndent()) {
    if (tokens.head() != "if") {
        throw new SourceException("Expected \"if\"", tokens.head());
    }
    auto start = tokens.head().start;
    tokens.advance();
    // Parse the condition expression
    auto condition = parseExpression(tokens);
    // Terminate the block header
    if (tokens.head() != ":") {
        throw new SourceException("Expected ':'", tokens.head());
    }
    auto end = tokens.head().end;
    tokens.advance();
    // The indentation of the block will be that of the first statement
    if (tokens.head().getKind() != Kind.INDENTATION) {
        throw new SourceException("Expected some indentation", tokens.head());
    }
    // Combine the current indentation to the found one
    auto blockIndentSpec = indentSpec + tokens.head().castOrFail!Indentation();
    // Parse the statements in the block
    auto trueStatements = parseStatements(tokens, blockIndentSpec);
    if (trueStatements.length > 0) {
        end = trueStatements[$ - 1].end;
    }
    // Try to follow it with an else block
    auto conditionBlocks = [ConditionalStatement.Block(condition, trueStatements, start, end)];
    auto falseStatements = parseConditionBlocks(tokens, indentSpec, blockIndentSpec, end, conditionBlocks);
    return new ConditionalStatement(conditionBlocks, falseStatements, end);
}

private Statement[] parseConditionBlocks(Tokenizer tokens, IndentSpec indentSpec, IndentSpec blockIndentSpec, ref size_t end,
        ref ConditionalStatement.Block[] conditionBlocks) {
    // Look for the parent indentation followed by "else"
    tokens.savePosition();
    if (!validateIndentation(tokens, indentSpec) || tokens.head() != "else") {
        // Otherwise return an empty else block
        tokens.restorePosition();
        return [];
    }
    tokens.discardPosition();
    auto start = tokens.head().start;
    tokens.advance();
    // This can also be an "else if" block
    Expression condition = null;
    if (tokens.head() == "if") {
        tokens.advance();
        // Parse the condition expression
        condition = parseExpression(tokens);
    }
    // Terminate the block header
    if (tokens.head() != ":") {
        throw new SourceException("Expected ':'", tokens.head());
    }
    end = tokens.head().end;
    tokens.advance();
    // Reuse the indentation of the "if" block to parse the statements
    auto statements = parseStatements(tokens, blockIndentSpec);
    if (statements.length > 0) {
        end = statements[$ - 1].end;
    }
    // If this is an "else if" block we can parse more "else" blocks
    if (condition !is null) {
        conditionBlocks ~= ConditionalStatement.Block(condition, statements, start, end);
        return parseConditionBlocks(tokens, indentSpec, blockIndentSpec, end, conditionBlocks);
    }
    return statements;
}

public LoopStatement parseLoopStatement(Tokenizer tokens, IndentSpec indentSpec = noIndent()) {
    if (tokens.head() != "while") {
        throw new SourceException("Expected \"while\"", tokens.head());
    }
    auto start = tokens.head().start;
    tokens.advance();
    // Parse the condition expression
    auto condition = parseExpression(tokens);
    // Terminate the block header
    if (tokens.head() != ":") {
        throw new SourceException("Expected ':'", tokens.head());
    }
    auto end = tokens.head().end;
    tokens.advance();
    // The indentation of the block will be that of the first statement
    if (tokens.head().getKind() != Kind.INDENTATION) {
        throw new SourceException("Expected some indentation", tokens.head());
    }
    // Combine the current indentation to the found one
    auto blockIndentSpec = indentSpec + tokens.head().castOrFail!Indentation();
    // Parse the statements in the block
    auto statements = parseStatements(tokens, blockIndentSpec);
    if (statements.length > 0) {
        end = statements[$ - 1].end;
    }
    return new LoopStatement(condition, statements, start, end);
}

public FunctionDefinition parseFunctionDefinition(Tokenizer tokens, IndentSpec indentSpec = noIndent()) {
    if (tokens.head() != "func") {
        throw new SourceException("Expected \"func\"", tokens.head());
    }
    auto start = tokens.head().start;
    tokens.advance();
    // Get the function name
    if (tokens.head().getKind() != Kind.IDENTIFIER) {
        throw new SourceException("Expected an identifier", tokens.head());
    }
    auto name = tokens.head().castOrFail!Identifier();
    tokens.advance();
    // Parse the parameter types
    auto parameters = parseFunctionDefinitionParameters(tokens);
    // Parse the return type
    NamedTypeAst returnType = null;
    if (tokens.head() != ":") {
        returnType = parseNamedType(tokens);
    }
    // Terminate the function signature
    if (tokens.head() != ":") {
        throw new SourceException("Expected ':'", tokens.head());
    }
    auto end = tokens.head().end;
    tokens.advance();
    // The indentation of the block will be that of the first statement
    if (tokens.head().getKind() != Kind.INDENTATION) {
        throw new SourceException("Expected some indentation", tokens.head());
    }
    // Combine the current indentation to the found one
    auto blockIndentSpec = indentSpec + tokens.head().castOrFail!Indentation();
    // Parse the statements in the block
    auto statements = parseStatements(tokens, blockIndentSpec);
    if (statements.length > 0) {
        end = statements[$ - 1].end;
    }
    return new FunctionDefinition(name, parameters, returnType, statements, start, end);
}

public FunctionDefinition.Parameter[] parseFunctionDefinitionParameters(Tokenizer tokens) {
    if (tokens.head() != "(") {
        throw new SourceException("Expected '('", tokens.head());
    }
    tokens.advance();
    if (tokens.head() == ")") {
        tokens.advance();
        return [];
    }
    // Parse comma separated pairs of named types and names
    FunctionDefinition.Parameter[] parameters = [parseFunctionDefinitionParameter(tokens)];
    while (tokens.head() == ",") {
        tokens.advance();
        parameters ~= parseFunctionDefinitionParameter(tokens);
    }
    if (tokens.head() != ")") {
        throw new SourceException("Expected ')'", tokens.head());
    }
    tokens.advance();
    return parameters;
}

public FunctionDefinition.Parameter parseFunctionDefinitionParameter(Tokenizer tokens) {
    auto type = parseNamedType(tokens);
    if (tokens.head().getKind() != Kind.IDENTIFIER) {
        throw new SourceException("Expected an identifier", tokens.head());
    }
    auto name = tokens.head().castOrFail!Identifier();
    tokens.advance();
    return FunctionDefinition.Parameter(type, name);
}

public Statement parseStatement(Tokenizer tokens, IndentSpec indentSpec = noIndent()) {
    switch (tokens.head().getSource()) {
        case "def":
            return parseTypeDefinition(tokens);
        case "let":
        case "var":
            return parseVariableDeclaration(tokens);
        case "if":
            return parseConditionalStatement(tokens, indentSpec);
        case "while":
            return parseLoopStatement(tokens, indentSpec);
        case "func":
            return parseFunctionDefinition(tokens, indentSpec);
        default:
            return parseAssigmnentOrFunctionCall(tokens);
    }
}

public Statement[] parseStatements(Tokenizer tokens, IndentSpec indentSpec = noIndent()) {
    Statement[] statements = [];
    bool empty = true;
    while (tokens.has()) {
        // Check if the indentation is valid for the current spec
        tokens.savePosition();
        if (!validateIndentation(tokens, indentSpec)) {
            if (indentSpec.count <= 0 || empty) {
                // This is a top level statement and the indentation needs to be correct
                // Or the block does not start with the proper indentation, which is also invalid
                tokens.discardPosition();
                throw new SourceException(format("Expected %s", indentSpec.toString()), tokens.head());
            }
            tokens.restorePosition();
            break;
        }
        tokens.discardPosition();
        indentSpec.nextIndentIgnored = false;
        // Check if this isn't an empty statement
        if (tokens.has() && tokens.head().getKind != Kind.TERMINATOR) {
            // Parse the statement
            statements ~= parseStatement(tokens, indentSpec);
        }
        empty = false;
        // Check for termination
        if (tokens.head().getKind() == Kind.TERMINATOR) {
            tokens.advance();
            // Can ignore indentation for the next statement if on the same line
            indentSpec.nextIndentIgnored = true;
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

private bool validateIndentation(Tokenizer tokens, IndentSpec indentSpec) {
    Indentation lastIndent = null;
    // Consume indentation preceding the statement
    while (tokens.head().getKind() == Kind.INDENTATION) {
        indentSpec.nextIndentIgnored = false;
        lastIndent = tokens.head().castOrFail!Indentation();
        tokens.advance();
    }
    // Indentation could precede end of source
    if (!tokens.has()) {
        return true;
    }
    // Only the last indentation before the statement matters
    return indentSpec.nextIndentIgnored || lastIndent !is null && indentSpec.validate(lastIndent);
}
