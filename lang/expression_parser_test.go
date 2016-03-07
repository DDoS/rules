package lang_test

import (
    "testing"
    "github.com/stretchr/testify/assert"
    "github.com/michael-golfi/rules/lang"
)

func TestParseAtom(t *testing.T) {
    assert.Equal(t,
        "test",
        parseTestExpression("test"),
    )
    assert.Equal(t,
        "ContextFieldAccess(.test)",
        parseTestExpression(".test"),
    )
    assert.Equal(t,
        "test.name",
        parseTestExpression("(test.name)"),
    )
    assert.Equal(t,
        "Initializer(hello{test.name, label: other.thing})",
        parseTestExpression("hello{test.name, label: other.thing}"),
    )
    assert.Equal(t,
        "Initializer(hello{2: test, 0xf1a: other, 0b00100: more})",
        parseTestExpression("hello{2: test, 0xf1a: other, 0b00100: more}"),
    )
    assert.Equal(t,
        "Initializer(test[]{DecimalIntegerLiteral(1), StringLiteral(\"2\"), CompositeLiteral({hey: FloatLiteral(2.1)})})",
        parseTestExpression("test[] {1, \"2\", {hey: 2.1}}"),
    )
}

func TestParseAccess(t *testing.T) {
    assert.Equal(t,
        "FieldAccess(StringLiteral(\"test\").length)",
        parseTestExpression("\"test\".length"),
    )
    assert.Equal(t,
        "FieldAccess(FieldAccess(DecimalIntegerLiteral(5).ucc).test)",
        parseTestExpression("5.ucc.test"),
    )
    assert.Equal(t,
        "FieldAccess(FieldAccess(HexadecimalIntegerLiteral(0xf).ucc).test)",
        parseTestExpression("0xf.ucc.test"),
    )
    assert.Equal(t,
        "FieldAccess(FieldAccess(FloatLiteral(5.).ucc).test)",
        parseTestExpression("5..ucc.test"),
    )
    assert.Equal(t,
        "ArrayAccess(StringLiteral(\"test\")[DecimalIntegerLiteral(2)])",
        parseTestExpression("\"test\"[2]"),
    )
    assert.Equal(t,
        "FunctionCall(FieldAccess(StringLiteral(\"test\").len)())",
        parseTestExpression("\"test\".len()"),
    )
    assert.Equal(t,
        "FunctionCall(FieldAccess(StringLiteral(\"test\").substring)(DecimalIntegerLiteral(1), DecimalIntegerLiteral(3)))",
        parseTestExpression("\"test\".substring(1, 3)"),
    )
}

func TestParseUnary(t *testing.T) {
    assert.Equal(t,
        "Sign(+test)",
        parseTestExpression("+test"),
    )
    assert.Equal(t,
        "Sign(+Sign(+test))",
        parseTestExpression("++test"),
    )
    assert.Equal(t,
        "Sign(+Sign(-test))",
        parseTestExpression("+-test"),
    )
    assert.Equal(t,
        "LogicalNot(!test)",
        parseTestExpression("!test"),
    )
    assert.Equal(t,
        "BitwiseNot(~test)",
        parseTestExpression("~test"),
    )
    assert.Equal(t,
        "Sign(-FieldAccess(StringLiteral(\"test\").length))",
        parseTestExpression("-\"test\".length"),
    )
}

func TestParseExponent(t *testing.T) {
    assert.Equal(t,
        "Exponent(test ** DecimalIntegerLiteral(12))",
        parseTestExpression("test ** 12"),
    )
    assert.Equal(t,
        "Exponent(Exponent(test ** another) ** more)",
        parseTestExpression("test ** another ** more"),
    )
    assert.Equal(t,
        "Exponent(FieldAccess(StringLiteral(\"1\").length) ** Sign(-DecimalIntegerLiteral(2)))",
        parseTestExpression("\"1\".length ** -2"),
    )
}

func TestParseInfix(t *testing.T) {
    assert.Equal(t,
        "Infix(u x v)",
        parseTestExpression("u x v"),
    )
    assert.Equal(t,
        "Infix(Infix(u cross v) dot w)",
        parseTestExpression("u cross v dot w"),
    )
    assert.Equal(t,
        "Infix(Sign(-u) x Exponent(v ** w))",
        parseTestExpression("-u x v ** w"),
    )
}

func TestParseMultiply(t *testing.T) {
    assert.Equal(t,
        "Multiply(u * v)",
        parseTestExpression("u * v"),
    )
    assert.Equal(t,
        "Multiply(Multiply(u / v) % w)",
        parseTestExpression("u / v % w"),
    )
    assert.Equal(t,
        "Multiply(Infix(u log m) * Infix(v ln w))",
        parseTestExpression("u log m * v ln w"),
    )
}

func TestParseAdd(t *testing.T) {
    assert.Equal(t,
        "Add(u + v)",
        parseTestExpression("u + v"),
    )
    assert.Equal(t,
        "Add(Add(u - v) + w)",
        parseTestExpression("u - v + w"),
    )
    assert.Equal(t,
        "Add(Multiply(u * m) + Multiply(v / w))",
        parseTestExpression("u * m + v / w"),
    )
}

func TestParseShift(t *testing.T) {
    assert.Equal(t,
        "Shift(u << v)",
        parseTestExpression("u << v"),
    )
    assert.Equal(t,
        "Shift(Shift(u << v) >> w)",
        parseTestExpression("u << v >> w"),
    )
    assert.Equal(t,
        "Shift(Add(u - m) >>> Add(v + w))",
        parseTestExpression("u - m >>> v + w"),
    )
}

func TestParseCompare(t *testing.T) {
    assert.Equal(t,
        "Compare(u == v)",
        parseTestExpression("u == v"),
    )
    assert.Equal(t,
        "Compare(u < v < w)",
        parseTestExpression("u < v < w"),
    )
    assert.Equal(t,
        "Compare(a == b < c > d <= e >= f :: g)",
        parseTestExpression("a == b < c > d <= e >= f :: g"),
    )
    assert.Equal(t,
        "Compare(a !: g)",
        parseTestExpression("a !: g"),
    )
    assert.Equal(t,
        "Compare(a <: g)",
        parseTestExpression("a <: g"),
    )
    assert.Equal(t,
        "Compare(a >: g)",
        parseTestExpression("a >: g"),
    )
    assert.Equal(t,
        "Compare(a <<: g)",
        parseTestExpression("a <<: g"),
    )
    assert.Equal(t,
        "Compare(a >>: g)",
        parseTestExpression("a >>: g"),
    )
    assert.Equal(t,
        "Compare(a <:> g[])",
        parseTestExpression("a <:> g[]"),
    )
    assert.Equal(t,
        "Compare(a == Compare(b < c > d) != Compare(e >= f))",
        parseTestExpression("a == (b < c > d) != (e >= f)"),
    )
    assert.Equal(t,
        "Compare(Add(u + v) <= Add(j - l) < Infix(a log b))",
        parseTestExpression("u + v <= j - l < a log b"),
    )
}

func TestParseBitwiseAnd(t *testing.T) {
    assert.Equal(t,
        "BitwiseAnd(u & v)",
        parseTestExpression("u & v"),
    )
    assert.Equal(t,
        "BitwiseAnd(BitwiseAnd(u & v) & w)",
        parseTestExpression("u & v & w"),
    )
    assert.Equal(t,
        "BitwiseAnd(Compare(u == m) & Compare(v != w))",
        parseTestExpression("u == m & v != w"),
    )
}

func TestParseBitwiseXor(t *testing.T) {
    assert.Equal(t,
        "BitwiseXor(u ^ v)",
        parseTestExpression("u ^ v"),
    )
    assert.Equal(t,
        "BitwiseXor(BitwiseXor(u ^ v) ^ w)",
        parseTestExpression("u ^ v ^ w"),
    )
    assert.Equal(t,
        "BitwiseXor(BitwiseAnd(u & m) ^ BitwiseAnd(v & w))",
        parseTestExpression("u & m ^ v & w"),
    )
}

func TestParseBitwiseOr(t *testing.T) {
    assert.Equal(t,
        "BitwiseOr(u | v)",
        parseTestExpression("u | v"),
    )
    assert.Equal(t,
        "BitwiseOr(BitwiseOr(u | v) | w)",
        parseTestExpression("u | v | w"),
    )
    assert.Equal(t,
        "BitwiseOr(BitwiseXor(u ^ m) | BitwiseXor(v ^ w))",
        parseTestExpression("u ^ m | v ^ w"),
    )
}

func TestParseLogicalAnd(t *testing.T) {
    assert.Equal(t,
        "LogicalAnd(u && v)",
        parseTestExpression("u && v"),
    )
    assert.Equal(t,
        "LogicalAnd(LogicalAnd(u && v) && w)",
        parseTestExpression("u && v && w"),
    )
    assert.Equal(t,
        "LogicalAnd(BitwiseOr(u | m) && BitwiseOr(v | w))",
        parseTestExpression("u | m && v | w"),
    )
}

func TestParseLogicalXor(t *testing.T) {
    assert.Equal(t,
        "LogicalXor(u ^^ v)",
        parseTestExpression("u ^^ v"),
    )
    assert.Equal(t,
        "LogicalXor(LogicalXor(u ^^ v) ^^ w)",
        parseTestExpression("u ^^ v ^^ w"),
    )
    assert.Equal(t,
        "LogicalXor(LogicalAnd(u && m) ^^ LogicalAnd(v && w))",
        parseTestExpression("u && m ^^ v && w"),
    )
}

func TestParseLogicalOr(t *testing.T) {
    assert.Equal(t,
        "LogicalOr(u || v)",
        parseTestExpression("u || v"),
    )
    assert.Equal(t,
        "LogicalOr(LogicalOr(u || v) || w)",
        parseTestExpression("u || v || w"),
    )
    assert.Equal(t,
        "LogicalOr(LogicalXor(u ^^ m) || LogicalXor(v ^^ w))",
        parseTestExpression("u ^^ m || v ^^ w"),
    )
}

func TestParseConcatenate(t *testing.T) {
    assert.Equal(t,
        "Concatenate(u ~ v)",
        parseTestExpression("u ~ v"),
    )
    assert.Equal(t,
        "Concatenate(Concatenate(u ~ v) ~ w)",
        parseTestExpression("u ~ v ~ w"),
    )
    assert.Equal(t,
        "Concatenate(LogicalOr(u || m) ~ LogicalOr(v || w))",
        parseTestExpression("u || m ~ v || w"),
    )
}

func TestParseRange(t *testing.T) {
    assert.Equal(t,
        "Range(u .. v)",
        parseTestExpression("u .. v"),
    )
    assert.Equal(t,
        "Range(u .. v)",
        parseTestExpression("u..v"),
    )
    assert.Equal(t,
        "Range(Range(u .. v) .. w)",
        parseTestExpression("u .. v .. w"),
    )
    assert.Equal(t,
        "Range(Concatenate(u ~ m) .. Concatenate(v ~ w))",
        parseTestExpression("u ~ m .. v ~ w"),
    )
}

func TestParseConditional(t *testing.T) {
    assert.Equal(t,
        "Conditional(u if v else w)",
        parseTestExpression("u if v else w"),
    )
    assert.Equal(t,
        "Conditional(Conditional(a if b else c) if Conditional(d if e else f) else Conditional(g if h else j))",
        parseTestExpression("(a if b else c) if (d if e else f) else (g if h else j)"),
    )
    assert.Equal(t,
        "Conditional(Range(a .. b) if Range(c .. d) else Range(e .. f))",
        parseTestExpression("a .. b if c .. d else e .. f"),
    )
}

func parseTestExpression(source string) string {
    tokenizer := lang.StringTokenizer(source);
    if tokenizer.Head().Kind == lang.INDENTATION {
        tokenizer.Advance()
    }
    return lang.ParseExpression(tokenizer).String()
}
