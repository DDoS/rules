package lang

func parseAssigmnent(tokens *Tokenizer) Statement {
    access := parseAccess(tokens)
    switch access.(type) {
    case *NameReference:
        break
    case *ContextFieldAccess:
        break
    case *FieldAccess:
        break
    case *ArrayAccess:
        break
    default:
        panic("Not a reference expression")
    }
    if tokens.Head().Kind != ASSIGNMENT_OPERATOR {
        panic("Expected an assignment operator")
    }
    operator := tokens.Head()
    tokens.Advance()
    var assignment Statement
    if operator.Is("=") && tokens.Head().Is("{") {
        assignment = &InitializerAssignment{access, parseCompositeLiteral(tokens)}
    } else {
        assignment = &Assignment{access, operator, ParseExpression(tokens)}
    }
    return assignment
}

func ParseStatment(tokens *Tokenizer) Statement {
    return parseAssigmnent(tokens)
}
