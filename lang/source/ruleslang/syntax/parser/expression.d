module ruleslang.syntax.parser.expression;

import std.conv : to;

import ruleslang.syntax.source;
import ruleslang.syntax.token;
import ruleslang.syntax.tokenizer;
import ruleslang.syntax.ast.type;
import ruleslang.syntax.ast.expression;
import ruleslang.syntax.parser.type;

private LabeledExpression parseCompositeLiteralPart(Tokenizer tokens) {
    Token label = null;
    auto headKind = tokens.head().getKind();
    if (headKind == Kind.IDENTIFIER || headKind == Kind.INTEGER_LITERAL) {
        label = tokens.head();
        tokens.savePosition();
        tokens.advance();
        if (tokens.head() == ":") {
            tokens.advance();
            tokens.discardPosition();
        } else {
            tokens.restorePosition();
            label = null;
        }
    }
    Expression value = void;
    if (tokens.head() == "{") {
        value = parseCompositeLiteral(tokens);
    } else {
        value = parseExpression(tokens);
    }
    return new LabeledExpression(label, value);
}

private LabeledExpression[] parseCompositeLiteralBody(Tokenizer tokens) {
    LabeledExpression[] values = [parseCompositeLiteralPart(tokens)];
    while (tokens.head() == ",") {
        tokens.advance();
        values ~= parseCompositeLiteralPart(tokens);
    }
    return values;
}

public CompositeLiteral parseCompositeLiteral(Tokenizer tokens) {
    if (tokens.head() != "{") {
        throw new SourceException("Expected '{'", tokens.head());
    }
    auto start = tokens.head().start;
    tokens.advance();
    LabeledExpression[] values = void;
    size_t end = void;
    if (tokens.head() == "}") {
        end = tokens.head().end;
        tokens.advance();
        values = [];
    } else {
        values = parseCompositeLiteralBody(tokens);
        if (tokens.head() != "}") {
            throw new SourceException("Expected '}'", tokens.head());
        }
        end = tokens.head().end;
        tokens.advance();
    }
    return new CompositeLiteral(values, start, end);
}

private Expression parseAtom(Tokenizer tokens) {
    if (tokens.head() == ".") {
        // Context field access
        auto start = tokens.head().start;
        tokens.advance();
        if (tokens.head().getKind() != Kind.IDENTIFIER) {
            throw new SourceException("Expected an identifier", tokens.head());
        }
        auto identifier = cast(Identifier) tokens.head();
        tokens.advance();
        return new ContextMemberAccess(identifier, start);
    }
    if (tokens.head().getKind() == Kind.IDENTIFIER) {
        // Name, or initializer
        tokens.savePosition();
        auto namedType = parseNamedType(tokens);
        if (tokens.head() != "{") {
            // Name
            tokens.restorePosition();
            auto name = parseName(tokens);
            return new NameReference(name);
        }
        tokens.discardPosition();
        auto value = parseCompositeLiteral(tokens);
        return new Initializer(namedType, value);
    }
    if (tokens.head() == "(") {
        // Parenthesis operator
        tokens.advance();
        auto expression = parseExpression(tokens);
        if (tokens.head() != ")") {
            throw new SourceException("Expected ')'", tokens.head());
        }
        tokens.advance();
        return expression;
    }
    // Check for a literal
    auto literal = cast(Expression) tokens.head();
    if (literal !is null) {
        tokens.advance();
        return literal;
    }
    throw new SourceException("Expected a literal, a name or '('", tokens.head());
}

public Expression parseAccess(Tokenizer tokens) {
    return parseAccess(tokens, parseAtom(tokens));
}

private Expression parseAccess(Tokenizer tokens, Expression value) {
    if (tokens.head() == ".") {
        tokens.advance();
        if (tokens.head().getKind() != Kind.IDENTIFIER) {
            throw new SourceException("Expected an identifier", tokens.head());
        }
        auto name = cast(Identifier) tokens.head();
        tokens.advance();
        return parseAccess(tokens, new MemberAccess(value, name));
    }
    if (tokens.head() == "[") {
        tokens.advance();
        auto index = parseExpression(tokens);
        if (tokens.head() != "]") {
            throw new SourceException("Expected ']'", tokens.head());
        }
        auto end = tokens.head().end;
        tokens.advance();
        return parseAccess(tokens, new ArrayAccess(value, index, end));
    }
    if (tokens.head() == "(") {
        tokens.advance();
        Expression[] arguments = void;
        size_t end = void;
        if (tokens.head() == ")") {
            end = tokens.head().end;
            tokens.advance();
            arguments = [];
        } else {
            arguments = parseExpressionList(tokens);
            if (tokens.head() != ")") {
                throw new SourceException("Expected ')'", tokens.head());
            }
            end = tokens.head().end;
            tokens.advance();
        }
        return parseAccess(tokens, new FunctionCall(value, arguments, end));
    }
    // Disambiguate between a float without decimal digits
    // and an integer with a field access
    auto token = cast(FloatLiteral) value;
    if (token !is null && tokens.head().getKind() == Kind.IDENTIFIER && token.getSource()[$ - 1] == '.') {
        auto name = cast(Identifier) tokens.head();
        tokens.advance();
        // The form decimalInt.identifier is lexed as float(numberSeq.)identifier
        // We detect it and convert it to first form here
        auto decimalInt = new IntegerLiteral(token.getSource()[0 .. $ - 1].to!dstring, token.start);
        return parseAccess(tokens, new MemberAccess(decimalInt, name));
    }
    return value;
}

private Expression parseUnary(Tokenizer tokens) {
    switch (tokens.head().getSource()) {
        case "+":
        case "-": {
            auto operator = cast(AddOperator) tokens.head();
            tokens.advance();
            auto inner = parseUnary(tokens);
            return new Sign(inner, operator);
        }
        case "~": {
            auto operator = cast(ConcatenateOperator) tokens.head();
            tokens.advance();
            auto inner = parseUnary(tokens);
            auto a = new BitwiseNot(inner, operator);
            return a;
        }
        case "!": {
            auto operator = cast(LogicalNotOperator) tokens.head();
            tokens.advance();
            auto inner = parseUnary(tokens);
            return new LogicalNot(inner, operator);
        }
        default:
            return parseAccess(tokens);
    }
}

private template parseBinary(alias parseChild, Bin : Binary!(name, Op), string name, Op) {
    private Expression parseBinary(Tokenizer tokens) {
        return parseBinary!(parseChild, Bin)(tokens, parseChild(tokens));
    }

    private Expression parseBinary(Tokenizer tokens, Expression value) {
        auto operator = cast(Op) tokens.head();
        if (operator !is null) {
            tokens.advance();
            auto exponent = parseChild(tokens);
            return parseBinary!(parseChild, Bin)(tokens, new Bin(value, exponent, operator));
        }
        return value;
    }
}

private alias parseExponent = parseBinary!(parseUnary, Exponent);
private alias parseInfix = parseBinary!(parseExponent, Infix);
private alias parseMultiply = parseBinary!(parseInfix, Multiply);
private alias parseAdd = parseBinary!(parseMultiply, Add);
private alias parseShift = parseBinary!(parseAdd, Shift);

private Expression parseCompare(Tokenizer tokens) {
    auto value = parseShift(tokens);
    if (tokens.head().getKind() != Kind.VALUE_COMPARE_OPERATOR &&
        tokens.head().getKind() != Kind.TYPE_COMPARE_OPERATOR) {
        return value;
    }
    ValueCompareOperator[] valueOperators = [];
    Expression[] values = [value];
    while (tokens.head().getKind() == Kind.VALUE_COMPARE_OPERATOR) {
        valueOperators ~= cast(ValueCompareOperator) tokens.head();
        tokens.advance();
        values ~= parseShift(tokens);
    }
    TypeCompareOperator typeOperator = null;
    Type type = null;
    if (tokens.head().getKind() == Kind.TYPE_COMPARE_OPERATOR) {
        typeOperator = cast(TypeCompareOperator) tokens.head();
        tokens.advance();
        type = parseType(tokens);
    }
    return new Compare(values, valueOperators, type, typeOperator);
}

private alias parseBitwiseAnd = parseBinary!(parseCompare, BitwiseAnd);
private alias parseBitwiseXor = parseBinary!(parseBitwiseAnd, BitwiseXor);
private alias parseBitwiseOr = parseBinary!(parseBitwiseXor, BitwiseOr);
private alias parseLogicalAnd = parseBinary!(parseBitwiseOr, LogicalAnd);
private alias parseLogicalXor = parseBinary!(parseLogicalAnd, LogicalXor);
private alias parseLogicalOr = parseBinary!(parseLogicalXor, LogicalOr);
private alias parseConcatenate = parseBinary!(parseLogicalOr, Concatenate);
private alias parseRange = parseBinary!(parseConcatenate, Range);

private Expression parseConditional(Tokenizer tokens) {
    auto trueValue = parseRange(tokens);
    if (tokens.head() != "if") {
        return trueValue;
    }
    tokens.advance();
    auto condition = parseRange(tokens);
    if (tokens.head() != "else") {
        throw new SourceException("Expected \"else\"", tokens.head());
    }
    tokens.advance();
    auto falseValue = parseConditional(tokens);
    return new Conditional(condition, trueValue, falseValue);
}

public Expression parseExpression(Tokenizer tokens) {
    return parseConditional(tokens);
}

public Expression[] parseExpressionList(Tokenizer tokens) {
    Expression[] expressions = [parseExpression(tokens)];
    while (tokens.head() == ",") {
        tokens.advance();
        expressions ~= parseExpression(tokens);
    }
    return expressions;
}
