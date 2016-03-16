package lang

import (
    "fmt"
    "github.com/michael-golfi/rules/lang/syntax"
)

var literalReducer = syntax.NewStatementModifier()

func init() {
    literalReducer.ModifyBinaryIntegerLiteral = test1
    literalReducer.ModifyDecimalIntegerLiteral = test2
    literalReducer.ModifyHexadecimalIntegerLiteral = test3
    literalReducer.ModifyAdd = addReducer
}

func ReduceLiterals(statement syntax.Statement) syntax.Statement {
    return statement.Accept(literalReducer)
}

func test1(s *syntax.BinaryIntegerLiteral) syntax.Expression {
    fmt.Println(s.Value())
    return s
}

func test2(s *syntax.DecimalIntegerLiteral) syntax.Expression {
    fmt.Println(s.Value())
    return s
}

func test3(s *syntax.HexadecimalIntegerLiteral) syntax.Expression {
    fmt.Println(s.Value())
    return s
}

func addReducer(add *syntax.Add) syntax.Expression {
    return add
}
