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
