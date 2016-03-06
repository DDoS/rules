package lang_test

import (
    "testing"
    "github.com/stretchr/testify/assert"
    "github.com/michael-golfi/rules/lang"
)

func TestParseAtom(t *testing.T) {
    assert.Equal(t,
        "test",
        lang.ParseExpression(lang.StringTokenizer("test")).String(),
    )
    assert.Equal(t,
        "ContextFieldAccess(.test)",
        lang.ParseExpression(lang.StringTokenizer(".test")).String(),
    )
    assert.Equal(t,
        "test.name",
        lang.ParseExpression(lang.StringTokenizer("(test.name)")).String(),
    )
    assert.Equal(t,
        "Initializer(hello{test.name, label: other.thing})",
        lang.ParseExpression(lang.StringTokenizer("hello{test.name, label: other.thing}")).String(),
    )
    assert.Equal(t,
        "Initializer(test[]{DecimalIntegerLiteral(1), StringLiteral(\"2\"), CompositeLiteral({hey: FloatLiteral(2.1)})})",
        lang.ParseExpression(lang.StringTokenizer("test[] {1, \"2\", {hey: 2.1}}")).String(),
    )
}

func TestParseAccess(t *testing.T) {
    assert.Equal(t,
        "FieldAccess(StringLiteral(\"test\").length)",
        lang.ParseExpression(lang.StringTokenizer("\"test\".length")).String(),
    )
    assert.Equal(t,
        "FieldAccess(FieldAccess(DecimalIntegerLiteral(5).ucc).test)",
        lang.ParseExpression(lang.StringTokenizer("5.ucc.test")).String(),
    )
    assert.Equal(t,
        "FieldAccess(FieldAccess(HexadecimalIntegerLiteral(0xf).ucc).test)",
        lang.ParseExpression(lang.StringTokenizer("0xf.ucc.test")).String(),
    )
    assert.Equal(t,
        "FieldAccess(FieldAccess(FloatLiteral(5.).ucc).test)",
        lang.ParseExpression(lang.StringTokenizer("5..ucc.test")).String(),
    )
    assert.Equal(t,
        "ArrayAccess(StringLiteral(\"test\")[DecimalIntegerLiteral(2)])",
        lang.ParseExpression(lang.StringTokenizer("\"test\"[2]")).String(),
    )
    assert.Equal(t,
        "FunctionCall(FieldAccess(StringLiteral(\"test\").len)())",
        lang.ParseExpression(lang.StringTokenizer("\"test\".len()")).String(),
    )
    assert.Equal(t,
        "FunctionCall(FieldAccess(StringLiteral(\"test\").substring)(DecimalIntegerLiteral(1), DecimalIntegerLiteral(3)))",
        lang.ParseExpression(lang.StringTokenizer("\"test\".substring(1, 3)")).String(),
    )
}

func TestParseUnary(t *testing.T) {
    assert.Equal(t,
        "Sign(+test)",
        lang.ParseExpression(lang.StringTokenizer("+test")).String(),
    )
    assert.Equal(t,
        "Sign(+Sign(+test))",
        lang.ParseExpression(lang.StringTokenizer("++test")).String(),
    )
    assert.Equal(t,
        "Sign(+Sign(-test))",
        lang.ParseExpression(lang.StringTokenizer("+-test")).String(),
    )
    assert.Equal(t,
        "LogicalNot(!test)",
        lang.ParseExpression(lang.StringTokenizer("!test")).String(),
    )
    assert.Equal(t,
        "BitwiseNot(~test)",
        lang.ParseExpression(lang.StringTokenizer("~test")).String(),
    )
    assert.Equal(t,
        "Sign(-FieldAccess(StringLiteral(\"test\").length))",
        lang.ParseExpression(lang.StringTokenizer("-\"test\".length")).String(),
    )
}

func TestParseExponent(t *testing.T) {
    assert.Equal(t,
        "Exponent(test ** DecimalIntegerLiteral(12))",
        lang.ParseExpression(lang.StringTokenizer("test ** 12")).String(),
    )
    assert.Equal(t,
        "Exponent(Exponent(test ** another) ** more)",
        lang.ParseExpression(lang.StringTokenizer("test ** another ** more")).String(),
    )
    assert.Equal(t,
        "Exponent(FieldAccess(StringLiteral(\"1\").length) ** Sign(-DecimalIntegerLiteral(2)))",
        lang.ParseExpression(lang.StringTokenizer("\"1\".length ** -2")).String(),
    )
}

func TestParseInfix(t *testing.T) {
    assert.Equal(t,
        "Infix(u x v)",
        lang.ParseExpression(lang.StringTokenizer("u x v")).String(),
    )
    assert.Equal(t,
        "Infix(Infix(u cross v) dot w)",
        lang.ParseExpression(lang.StringTokenizer("u cross v dot w")).String(),
    )
    assert.Equal(t,
        "Infix(Sign(-u) x Exponent(v ** w))",
        lang.ParseExpression(lang.StringTokenizer("-u x v ** w")).String(),
    )
}

func TestParseMultiply(t *testing.T) {
    assert.Equal(t,
        "Multiply(u * v)",
        lang.ParseExpression(lang.StringTokenizer("u * v")).String(),
    )
    assert.Equal(t,
        "Multiply(Multiply(u / v) % w)",
        lang.ParseExpression(lang.StringTokenizer("u / v % w")).String(),
    )
    assert.Equal(t,
        "Multiply(Infix(u log m) * Infix(v ln w))",
        lang.ParseExpression(lang.StringTokenizer("u log m * v ln w")).String(),
    )
}

func TestParseAdd(t *testing.T) {
    assert.Equal(t,
        "Add(u + v)",
        lang.ParseExpression(lang.StringTokenizer("u + v")).String(),
    )
    assert.Equal(t,
        "Add(Add(u - v) + w)",
        lang.ParseExpression(lang.StringTokenizer("u - v + w")).String(),
    )
    assert.Equal(t,
        "Add(Multiply(u * m) + Multiply(v / w))",
        lang.ParseExpression(lang.StringTokenizer("u * m + v / w")).String(),
    )
}
