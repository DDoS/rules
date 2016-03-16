package lang

import (
    "fmt"
    "github.com/michael-golfi/rules/lang/syntax"
)

var literalReducer = syntax.NewStatementModifier()

func init() {
    literalReducer.ModifyStringLiteral = test
    literalReducer.ModifyAdd = addReducer
}

func ReduceLiterals(statement syntax.Statement) syntax.Statement {
    return statement.Accept(literalReducer)
}

func test(s *syntax.StringLiteral) syntax.Expression {
    fmt.Println(string(s.Value()))
    return s
}

func addReducer(add *syntax.Add) syntax.Expression {
    return add
}
