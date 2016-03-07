package lang_test

import (
    "testing"
    "github.com/stretchr/testify/assert"
    "github.com/michael-golfi/rules/lang"
)

func TestAssignment(t *testing.T) {
    assert.Equal(t,
        "Assignment(a = DecimalIntegerLiteral(1))",
        lang.ParseStatment(lang.StringTokenizer("a = 1")).String(),
    )
    assert.Equal(t,
        "Assignment(a.b *= v)",
        lang.ParseStatment(lang.StringTokenizer("a.b *= v")).String(),
    )
    assert.Equal(t,
        "Assignment(FieldAccess(FunctionCall(a.test()).field) ~= StringLiteral(\"2\"))",
        lang.ParseStatment(lang.StringTokenizer("a.test().field ~= \"2\"")).String(),
    )
    assert.Equal(t,
        "InitializerAssignment(a = CompositeLiteral({a, b, CompositeLiteral({v})}))",
        lang.ParseStatment(lang.StringTokenizer("a = {a, b, {v}}")).String(),
    )
}

func TestFunctionCall(t *testing.T) {
    assert.Equal(t,
        "FunctionCall(a())",
        lang.ParseStatment(lang.StringTokenizer("a()")).String(),
    )
    assert.Equal(t,
        "FunctionCall(a(DecimalIntegerLiteral(1), b))",
        lang.ParseStatment(lang.StringTokenizer("a(1, b)")).String(),
    )
    assert.Equal(t,
        "FunctionCall(a.b())",
        lang.ParseStatment(lang.StringTokenizer("a.b()")).String(),
    )
    assert.Equal(t,
        "FunctionCall(FieldAccess(StringLiteral(\"test\").length)())",
        lang.ParseStatment(lang.StringTokenizer("\"test\".length()")).String(),
    )
    assert.Equal(t,
        "FunctionCall(FieldAccess(Infix(DecimalIntegerLiteral(2) log b).test)())",
        lang.ParseStatment(lang.StringTokenizer("(2 log b).test()")).String(),
    )
}

func TestParseStatments(t *testing.T) {
    assert.Equal(t,
        "FunctionCall(a()); Assignment(a = DecimalIntegerLiteral(1)); FunctionCall(a.b()); Assignment(a.b *= v)",
        toString(lang.ParseStatments(lang.StringTokenizer("a()\na = 1; a.b();\n\t\ra.b *= v"))),
    )
}

func toString(statements []lang.Statement) string {
    s := ""
    length := len(statements) - 1
    for i := 0; i < length; i++ {
        s += statements[i].String() + "; "
    }
    s += statements[length].String()
    return s
}
