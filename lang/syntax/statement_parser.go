package syntax

import "fmt"

type IndentSpec struct {
    char rune
    count int
    nextIgnored bool
}

func (this *IndentSpec) validate(indentation *IndentationToken) bool {
    if len(indentation.Source()) != this.count {
        return false
    }
    for _, c := range indentation.Source() {
        if c != this.char {
            return false
        }
    }
    return true
}

var NO_INDENTATION = &IndentSpec{' ', 0, false}

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
    if tokens.Head().Kind() != ASSIGNMENT_OPERATOR {
        panic("Expected an assignment operator")
    }
    operator := tokens.Head().(*SymbolToken)
    tokens.Advance()
    if operator.Is("=") && tokens.Head().Is("{") {
        return &InitializerAssignment{access, parseCompositeLiteral(tokens)}
    }
    return &Assignment{access, operator, ParseExpression(tokens)}
}

func ParseStatment(tokens *Tokenizer) Statement {
    return parseStatment(tokens, NO_INDENTATION)
}

func parseStatment(tokens *Tokenizer, indentSpec *IndentSpec) Statement {
    validIndent := indentSpec.nextIgnored
    indentSpec.nextIgnored = false
    // Consume indentation preceding the statement
    for tokens.Head().Kind() == INDENTATION {
        validIndent = indentSpec.validate(tokens.Head().(*IndentationToken))
        tokens.Advance()
    }
    // Only the last indentation before the statement matters
    if !validIndent {
        panic(fmt.Sprintf("Expected %d of %q as indentation", indentSpec.count, indentSpec.char))
    }
    return parseAssigmnentOrFunctionCall(tokens)
}

func ParseStatments(tokens *Tokenizer) []Statement {
    return parseStatments(tokens, NO_INDENTATION)
}

func parseStatments(tokens *Tokenizer, indentSpec *IndentSpec) []Statement {
    statements := []Statement{}
    for tokens.Has() {
        statements = append(statements, parseStatment(tokens, indentSpec))
        if tokens.Head().Kind() == TERMINATOR {
            tokens.Advance()
            // Can ignore indentation for the next statement if on the same line
            indentSpec.nextIgnored = true
            continue
        }
        if tokens.Head().Kind() == INDENTATION {
            // Indentation marks a new statement, so the end of the current one
            continue
        }
        if tokens.Head().Kind() == EOF {
            // Nothing else to parse
            break
        }
        panic("Expected end of statement")
    }
    return statements
}
