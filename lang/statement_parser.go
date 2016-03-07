package lang

func parseAssigmnentOrFunctionCall(tokens *Tokenizer) Statement {
    access := parseAccess(tokens)
    switch t := access.(type) {
    case *NameReference:
        break
    case *ContextFieldAccess:
        break
    case *FieldAccess:
        break
    case *ArrayAccess:
        break
    case *FunctionCall:
        return t
    default:
        panic("Not a reference expression")
    }
    if tokens.Head().Kind != ASSIGNMENT_OPERATOR {
        panic("Expected an assignment operator")
    }
    operator := tokens.Head()
    tokens.Advance()
    if operator.Is("=") && tokens.Head().Is("{") {
        return &InitializerAssignment{access, parseCompositeLiteral(tokens)}
    }
    return &Assignment{access, operator, ParseExpression(tokens)}
}

func ParseStatment(tokens *Tokenizer) Statement {
    return parseAssigmnentOrFunctionCall(tokens)
}
