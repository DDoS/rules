package lang

import (
    "github.com/michael-golfi/rules/lang/syntax"
)

var literalReducer = syntax.NewStatementModifier()

func init() {
    literalReducer.ModifyAdd = addReducer
}

func ReduceLiterals(statement syntax.Statement) syntax.Statement {
    return statement.Accept(literalReducer)
}

func addReducer(add *syntax.Add) syntax.Expression {
    return add
}
