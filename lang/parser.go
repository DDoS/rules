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
// TODO: use usual asignment and equal operators?
func parseAtom(tokens *Tokenizer) Expression {
    if tokens.Head().Kind.IsLiteral() {
        // Literal
        literal := tokens.Head()
        tokens.Advance()
        return literal
    }
    if tokens.Head().Is(".") {
        tokens.Advance()
        if tokens.Head().Kind != IDENTIFIER {
            panic("Expected an identifier")
        }
        identifier := tokens.Head()
        tokens.Advance()
        return &ContextFieldAccess{identifier}
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

func parseAccess(tokens *Tokenizer) Expression {
    return parseAccessOn(tokens, parseAtom(tokens))
}

func parseAccessOn(tokens *Tokenizer, object Expression) Expression {
    if tokens.Head().Is(".") {
        tokens.Advance()
        if tokens.Head().Kind != IDENTIFIER {
            panic("Expected an identifier")
        }
        name := tokens.Head()
        tokens.Advance()
        return parseAccessOn(tokens, &FieldAccess{object, name})
    }
    if tokens.Head().Is("[") {
        tokens.Advance()
        index := ParseExpression(tokens)
        if !tokens.Head().Is("]") {
            panic("Expected ']'")
        }
        tokens.Advance()
        return parseAccessOn(tokens, &ArrayAccess{object, index})
    }
    if tokens.Head().Is("(") {
        tokens.Advance()
        var arguments []Expression
        if tokens.Head().Is(")") {
            tokens.Advance()
            arguments = []Expression{}
        } else {
            arguments = parseExpressionList(tokens)
            if !tokens.Head().Is(")") {
                panic("Expected ')'")
            }
            tokens.Advance()
        }
        return parseAccessOn(tokens, &FunctionCall{object, arguments})
    }
    // Disambiguate between a float without decimal digits
    // and an integer with a field access
    token, ok := object.(*Token)
    if ok && token.Kind == FLOAT_LITERAL && tokens.Head().Kind == IDENTIFIER &&
            token.Source[len(token.Source) - 1] == '.' {
        name := tokens.Head()
        tokens.Advance()
        // The form decimalInt.identifier is lexed as float(numberSeq.)identifier
        // We detect it and convert it to first form here
        decimalInt := &Token{token.Source[:len(token.Source) - 1], DECIMAL_INTEGER_LITERAL}
        return parseAccessOn(tokens, &FieldAccess{decimalInt, name})
    }
    return object
}

func ParseExpression(tokens *Tokenizer) Expression {
    return parseAccess(tokens)
}

func parseExpressionList(tokens *Tokenizer) []Expression {
    expressions := []Expression{ParseExpression(tokens)}
    for tokens.Head().Is(",") {
        tokens.Advance()
        expressions = append(expressions, ParseExpression(tokens))
    }
    return expressions
}
