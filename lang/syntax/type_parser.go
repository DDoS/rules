package syntax

func parseName(tokens *Tokenizer) []*Identifier {
    if tokens.Head().Kind() != IDENTIFIER {
        panic("Expected an identifier")
    }
    name := []*Identifier{tokens.Head().(*Identifier)}
    tokens.Advance()
    for tokens.Head().Is(".") {
        tokens.Advance()
        if tokens.Head().Kind() != IDENTIFIER {
            panic("Expected an identifier")
        }
        name = append(name, tokens.Head().(*Identifier))
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

func parseType(tokens *Tokenizer) Type {
    return parseNamedType(tokens)
}
