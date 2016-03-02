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

func parseArrayInitializer(tokens *Tokenizer) []Expression {
    if !tokens.Head().Is("[") {
        panic("Expected '['")
    }
    sizes := []Expression{}
    for tokens.Head().Is("[") {
        tokens.Advance()
        if tokens.Head().Is("]") {
            tokens.Advance()
            sizes = append(sizes, nil)
        } else {
            sizes = append(sizes, ParseExpression(tokens))
            if !tokens.Head().Is("]") {
                panic("Expected ']'")
            }
            tokens.Advance()
        }
    }
    return sizes
}

func ParseExpressionList(tokens *Tokenizer) []Expression {
    expressions := []Expression{ParseExpression(tokens)}
    for tokens.Head().Is(",") {
        tokens.Advance()
        expressions = append(expressions, ParseExpression(tokens))
    }
    return expressions
}

func parseArrayLiteral(tokens *Tokenizer) []Expression {
    if !tokens.Head().Is("{") {
        panic("Expected '{'")
    }
    tokens.Advance()
    if tokens.Head().Is("}") {
        tokens.Advance()
        return []Expression{}
    }
    expressions := ParseExpressionList(tokens)
    if !tokens.Head().Is("}") {
        panic("Expected '}'")
    }
    tokens.Advance()
    return expressions
}

func parseAtom(tokens *Tokenizer) Expression {
    if tokens.Head().Kind.IsLiteral() {
        // Literal
        literal := tokens.Head()
        tokens.Advance()
        return literal
    }
    if tokens.Head().Kind == IDENTIFIER {
        // Name, array access, or array or object literal
        name := parseName(tokens)
        if tokens.Head().Is("[") {
            tokens.SavePosition()
            arrayInitializer := parseArrayInitializer(tokens)
            if !tokens.Head().Is("{") {
                // Name
                tokens.RestorePosition()
                return &NameReference{name}
            }
            tokens.DiscardPosition()
            // Array literal
            literal := parseArrayLiteral(tokens)
            return &ArrayLiteral{NamedType{name}, arrayInitializer, literal}
        }
        if tokens.Head().Is("{") {
            // Object literal
        }
        // Name
        return &NameReference{name}
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
