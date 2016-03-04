package lang

func parseName(tokens *Tokenizer) []*Token {
    if tokens.Head().Kind != IDENTIFIER {
        panic("Expected an identifier")
    }
    name := []*Token{tokens.Head()}
    tokens.Advance()
    for tokens.Head().Is(".") {
        tokens.Advance()
        if tokens.Head().Kind != IDENTIFIER {
            panic("Expected an identifier")
        }
        name = append(name, tokens.Head())
        tokens.Advance()
    }
    return name
}

func parseArrayDimension(tokens *Tokenizer) Expression {
    if !tokens.Head().Is("[") {
        panic("Expected '['")
    }
    tokens.Advance()
    if tokens.Head().Is("]") {
        tokens.Advance()
        return nil
    }
    size := ParseExpression(tokens)
    if !tokens.Head().Is("]") {
        panic("Expected ']'")
    }
    tokens.Advance()
    return size
}

func parseNamedType(tokens *Tokenizer) *NamedType {
    name := parseName(tokens)
    dimensions := []Expression{}
    for tokens.Head().Is("[") {
        dimensions = append(dimensions, parseArrayDimension(tokens))
    }
    return &NamedType{name, dimensions}
}

func parseCompositeLiteralPart(tokens *Tokenizer) *LabeledExpression {
    var label *Token = nil
    if tokens.Head().Kind == IDENTIFIER {
        label = tokens.Head()
        tokens.SavePosition()
        tokens.Advance()
        if tokens.Head().Is(":") {
            tokens.Advance()
            tokens.DiscardPosition()
        } else {
            tokens.RestorePosition()
            label = nil
        }
    }
    var value Expression
    if tokens.Head().Is("{") {
        value = parseCompositeLiteral(tokens)
    } else {
        value = ParseExpression(tokens)
    }
    return &LabeledExpression{label, value}
}

func parseCompositeLiteralBody(tokens *Tokenizer) []*LabeledExpression {
    body := []*LabeledExpression{parseCompositeLiteralPart(tokens)}
    for tokens.Head().Is(",") {
        tokens.Advance()
        body = append(body, parseCompositeLiteralPart(tokens))
    }
    return body
}

func parseCompositeLiteral(tokens *Tokenizer) *CompositeLiteral {
    if !tokens.Head().Is("{") {
        panic("Expected '{'")
    }
    tokens.Advance()
    var body []*LabeledExpression
    if tokens.Head().Is("}") {
        tokens.Advance()
        body = []*LabeledExpression{}
    } else {
        body = parseCompositeLiteralBody(tokens)
        if !tokens.Head().Is("}") {
            panic("Expected '}'")
        }
    }
    return &CompositeLiteral{body}
}

func parseAtom(tokens *Tokenizer) Expression {
    if tokens.Head().Kind.IsLiteral() {
        // Literal
        literal := tokens.Head()
        tokens.Advance()
        return literal
    }
    if tokens.Head().Kind == IDENTIFIER {
        // Name, or initializer
        tokens.SavePosition()
        namedType := parseNamedType(tokens)
        if !tokens.Head().Is("{") {
            // Name
            tokens.RestorePosition()
            name := parseName(tokens)
            return &NameReference{name}
        }
        tokens.DiscardPosition()
        value := parseCompositeLiteral(tokens)
        return &Initializer{namedType, value}
    }
    if tokens.Head().Is("(") {
        // Parenthesis operator
        tokens.Advance()
        expression := ParseExpression(tokens)
        if !tokens.Head().Is(")") {
            panic("Expected ')'")
        }
        tokens.Advance()
        return expression
    }
    panic("Expected a literal, a name or '('")
}

func ParseExpression(tokens *Tokenizer) Expression {
    return parseAtom(tokens)
}

func parseExpressionList(tokens *Tokenizer) []Expression {
    expressions := []Expression{ParseExpression(tokens)}
    for tokens.Head().Is(",") {
        tokens.Advance()
        expressions = append(expressions, ParseExpression(tokens))
    }
    return expressions
}
