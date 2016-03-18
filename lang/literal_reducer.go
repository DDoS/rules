package lang

import (
    "github.com/michael-golfi/rules/lang/syntax"
)

var literalReducer = syntax.NewStatementModifier()

func init() {
    literalReducer.ModifySign = signReducer
}

func ReduceLiterals(statement syntax.Statement) syntax.Statement {
    return statement.Accept(literalReducer)
}

func signReducer(sign *syntax.Sign) syntax.Expression {
    switch t := sign.Inner.(type) {
    case *syntax.IntegerLiteral:
        value := t.Value()
        value.Neg(value)
        return syntax.NewIntegerLiteralFromValue(value)
    case *syntax.FloatLiteral:
        value := t.Value()
        value.Neg(value)
        return syntax.NewFloatLiteralFromValue(value)
    default:
        return t
    }
}
