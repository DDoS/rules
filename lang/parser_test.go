package lang_test

import (
    "testing"
    "github.com/stretchr/testify/assert"
    "github.com/michael-golfi/rules/lang"
)

func TestParseAtom(t *testing.T) {
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
