package syntax_test

import (
    "testing"
    "github.com/stretchr/testify/assert"
    "github.com/michael-golfi/rules/lang/syntax"
)

func TestAssignment(t *testing.T) {
    assert.Equal(t,
        "Assignment(a = DecimalIntegerLiteral(1))",
        syntax.ParseStatment(syntax.StringTokenizer("a = 1")).String(),
    )
    assert.Equal(t,
        "Assignment(a.b *= v)",
        syntax.ParseStatment(syntax.StringTokenizer("a.b *= v")).String(),
    )
    assert.Equal(t,
        "Assignment(FieldAccess(FunctionCall(a.test()).field) ~= StringLiteral(\"2\"))",
        syntax.ParseStatment(syntax.StringTokenizer("a.test().field ~= \"2\"")).String(),
    )
    assert.Equal(t,
        "InitializerAssignment(a = CompositeLiteral({a, b, CompositeLiteral({v})}))",
        syntax.ParseStatment(syntax.StringTokenizer("a = {a, b, {v}}")).String(),
    )
}

func TestFunctionCall(t *testing.T) {
    assert.Equal(t,
        "FunctionCall(a())",
        syntax.ParseStatment(syntax.StringTokenizer("a()")).String(),
    )
    assert.Equal(t,
        "FunctionCall(a(DecimalIntegerLiteral(1), b))",
        syntax.ParseStatment(syntax.StringTokenizer("a(1, b)")).String(),
    )
    assert.Equal(t,
        "FunctionCall(a.b())",
        syntax.ParseStatment(syntax.StringTokenizer("a.b()")).String(),
    )
    assert.Equal(t,
        "FunctionCall(FieldAccess(StringLiteral(\"test\").length)())",
        syntax.ParseStatment(syntax.StringTokenizer("\"test\".length()")).String(),
    )
    assert.Equal(t,
        "FunctionCall(FieldAccess(Infix(DecimalIntegerLiteral(2) log b).test)())",
        syntax.ParseStatment(syntax.StringTokenizer("(2 log b).test()")).String(),
    )
}

func TestParseStatments(t *testing.T) {
    assert.Equal(t,
        "FunctionCall(a()); Assignment(a = DecimalIntegerLiteral(1)); FunctionCall(a.b()); Assignment(a.b *= v)",
        toString(syntax.ParseStatments(syntax.StringTokenizer("a()\na = 1; a.b();\n\t\ra.b *= v"))),
    )
}

func toString(statements []syntax.Statement) string {
    s := ""
    length := len(statements) - 1
    for i := 0; i < length; i++ {
        s += statements[i].String() + "; "
    }
    s += statements[length].String()
    return s
}
