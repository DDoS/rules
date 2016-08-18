module ruleslang.test.parser.expression;

import ruleslang.syntax.source;
import ruleslang.syntax.token;
import ruleslang.syntax.tokenizer;
import ruleslang.syntax.parser.expression;

import ruleslang.test.assertion;

unittest {
    assertEqual(
        "test",
        parseTestExpression("test")
    );
    assertEqual(
        "ContextMemberAccess(.test)",
        parseTestExpression(".test")
    );
    assertEqual(
        "test.name",
        parseTestExpression("(test.name)")
    );
    assertEqual(
        "CompositeLiteral({test.name, label: other.thing})",
        parseTestExpression("{test.name, label: other.thing}")
    );
    assertEqual(
        "CompositeLiteral({SignedIntegerLiteral(1), StringLiteral(\"2\"), CompositeLiteral({hey: FloatLiteral(2.1)})})",
        parseTestExpression("{1, \"2\", {hey: 2.1}}")
    );
    assertEqual(
        "Initializer(hello{test.name, label: other.thing})",
        parseTestExpression("hello{test.name, label: other.thing}")
    );
    assertEqual(
        "Initializer(hello{2: test, 0xf1a: other, 0b00100: more})",
        parseTestExpression("hello{2: test, 0xf1a: other, 0b00100: more}")
    );
    assertEqual(
        "Initializer(test[]{SignedIntegerLiteral(1), StringLiteral(\"2\"), CompositeLiteral({hey: FloatLiteral(2.1)})})",
        parseTestExpression("test[] {1, \"2\", {hey: 2.1}}")
    );
    assertEqual(
        "MemberAccess(StringLiteral(\"test\").length)",
        parseTestExpression("\"test\".length")
    );
}

unittest {
    assertEqual(
        "MemberAccess(StringLiteral(\"test\").length)",
        parseTestExpression("\"test\".length")
    );
    assertEqual(
        "MemberAccess(MemberAccess(SignedIntegerLiteral(5).ucc).test)",
        parseTestExpression("5.ucc.test")
    );
    assertEqual(
        "MemberAccess(MemberAccess(SignedIntegerLiteral(0xf).ucc).test)",
        parseTestExpression("0xf.ucc.test")
    );
    assertEqual(
        "MemberAccess(MemberAccess(FloatLiteral(5.).ucc).test)",
        parseTestExpression("5..ucc.test")
    );
    assertEqual(
        "ArrayAccess(StringLiteral(\"test\")[SignedIntegerLiteral(2)])",
        parseTestExpression("\"test\"[2]")
    );
    assertEqual(
        "FunctionCall(MemberAccess(StringLiteral(\"test\").len)())",
        parseTestExpression("\"test\".len()")
    );
    assertEqual(
        "FunctionCall(MemberAccess(StringLiteral(\"test\").substring)(SignedIntegerLiteral(1), SignedIntegerLiteral(3)))",
        parseTestExpression("\"test\".substring(1, 3)")
    );
}

unittest {
    assertEqual(
        "Sign(+test)",
        parseTestExpression("+test")
    );
    assertEqual(
        "Sign(+Sign(+test))",
        parseTestExpression("++test")
    );
    assertEqual(
        "Sign(+Sign(-test))",
        parseTestExpression("+-test")
    );
    assertEqual(
        "LogicalNot(!test)",
        parseTestExpression("!test")
    );
    assertEqual(
        "BitwiseNot(~test)",
        parseTestExpression("~test")
    );
    assertEqual(
        "Sign(-MemberAccess(StringLiteral(\"test\").length))",
        parseTestExpression("-\"test\".length")
    );
}

unittest {
    assertEqual(
        "Exponent(test ** SignedIntegerLiteral(12))",
        parseTestExpression("test ** 12")
    );
    assertEqual(
        "Exponent(Exponent(test ** another) ** more)",
        parseTestExpression("test ** another ** more")
    );
    assertEqual(
        "Exponent(MemberAccess(StringLiteral(\"1\").length) ** Sign(-SignedIntegerLiteral(2)))",
        parseTestExpression("\"1\".length ** -2")
    );
}

unittest {
    assertEqual(
        "Infix(u x v)",
        parseTestExpression("u x v")
    );
    assertEqual(
        "Infix(Infix(u cross v) dot w)",
        parseTestExpression("u cross v dot w")
    );
    assertEqual(
        "Infix(Sign(-u) x Exponent(v ** w))",
        parseTestExpression("-u x v ** w")
    );
}

unittest {
    assertEqual(
        "Multiply(u * v)",
        parseTestExpression("u * v")
    );
    assertEqual(
        "Multiply(Multiply(u / v) % w)",
        parseTestExpression("u / v % w")
    );
    assertEqual(
        "Multiply(Infix(u log m) * Infix(v ln w))",
        parseTestExpression("u log m * v ln w")
    );
}

unittest {
    assertEqual(
        "Add(u + v)",
        parseTestExpression("u + v")
    );
    assertEqual(
        "Add(Add(u - v) + w)",
        parseTestExpression("u - v + w")
    );
    assertEqual(
        "Add(Multiply(u * m) + Multiply(v / w))",
        parseTestExpression("u * m + v / w")
    );
}

unittest {
    assertEqual(
        "Shift(u << v)",
        parseTestExpression("u << v")
    );
    assertEqual(
        "Shift(Shift(u << v) >> w)",
        parseTestExpression("u << v >> w")
    );
    assertEqual(
        "Shift(Add(u - m) >>> Add(v + w))",
        parseTestExpression("u - m >>> v + w")
    );
}

unittest {
    assertEqual(
        "Compare(u == v)",
        parseTestExpression("u == v")
    );
    assertEqual(
        "Compare(u < v < w)",
        parseTestExpression("u < v < w")
    );
    assertEqual(
        "Compare(a == b < c > d <= e >= f :: g)",
        parseTestExpression("a == b < c > d <= e >= f :: g")
    );
    assertEqual(
        "Compare(a !: g)",
        parseTestExpression("a !: g")
    );
    assertEqual(
        "Compare(a <: g)",
        parseTestExpression("a <: g")
    );
    assertEqual(
        "Compare(a >: g)",
        parseTestExpression("a >: g")
    );
    assertEqual(
        "Compare(a <<: g)",
        parseTestExpression("a <<: g")
    );
    assertEqual(
        "Compare(a >>: g)",
        parseTestExpression("a >>: g")
    );
    assertEqual(
        "Compare(a <:> g[])",
        parseTestExpression("a <:> g[]")
    );
    assertEqual(
        "Compare(a == Compare(b < c > d) != Compare(e >= f))",
        parseTestExpression("a == (b < c > d) != (e >= f)")
    );
    assertEqual(
        "Compare(Add(u + v) <= Add(j - l) < Infix(a log b))",
        parseTestExpression("u + v <= j - l < a log b")
    );
}

unittest {
    assertEqual(
        "BitwiseAnd(u & v)",
        parseTestExpression("u & v")
    );
    assertEqual(
        "BitwiseAnd(BitwiseAnd(u & v) & w)",
        parseTestExpression("u & v & w")
    );
    assertEqual(
        "BitwiseAnd(Compare(u == m) & Compare(v != w))",
        parseTestExpression("u == m & v != w")
    );
}

unittest {
    assertEqual(
        "BitwiseXor(u ^ v)",
        parseTestExpression("u ^ v")
    );
    assertEqual(
        "BitwiseXor(BitwiseXor(u ^ v) ^ w)",
        parseTestExpression("u ^ v ^ w")
    );
    assertEqual(
        "BitwiseXor(BitwiseAnd(u & m) ^ BitwiseAnd(v & w))",
        parseTestExpression("u & m ^ v & w")
    );
}

unittest {
    assertEqual(
        "BitwiseOr(u | v)",
        parseTestExpression("u | v")
    );
    assertEqual(
        "BitwiseOr(BitwiseOr(u | v) | w)",
        parseTestExpression("u | v | w")
    );
    assertEqual(
        "BitwiseOr(BitwiseXor(u ^ m) | BitwiseXor(v ^ w))",
        parseTestExpression("u ^ m | v ^ w")
    );
}

unittest {
    assertEqual(
        "LogicalAnd(u && v)",
        parseTestExpression("u && v")
    );
    assertEqual(
        "LogicalAnd(LogicalAnd(u && v) && w)",
        parseTestExpression("u && v && w")
    );
    assertEqual(
        "LogicalAnd(BitwiseOr(u | m) && BitwiseOr(v | w))",
        parseTestExpression("u | m && v | w")
    );
}

unittest {
    assertEqual(
        "LogicalXor(u ^^ v)",
        parseTestExpression("u ^^ v")
    );
    assertEqual(
        "LogicalXor(LogicalXor(u ^^ v) ^^ w)",
        parseTestExpression("u ^^ v ^^ w")
    );
    assertEqual(
        "LogicalXor(LogicalAnd(u && m) ^^ LogicalAnd(v && w))",
        parseTestExpression("u && m ^^ v && w")
    );
}

unittest {
    assertEqual(
        "LogicalOr(u || v)",
        parseTestExpression("u || v")
    );
    assertEqual(
        "LogicalOr(LogicalOr(u || v) || w)",
        parseTestExpression("u || v || w")
    );
    assertEqual(
        "LogicalOr(LogicalXor(u ^^ m) || LogicalXor(v ^^ w))",
        parseTestExpression("u ^^ m || v ^^ w")
    );
}

unittest {
    assertEqual(
        "Concatenate(u ~ v)",
        parseTestExpression("u ~ v")
    );
    assertEqual(
        "Concatenate(Concatenate(u ~ v) ~ w)",
        parseTestExpression("u ~ v ~ w")
    );
    assertEqual(
        "Concatenate(LogicalOr(u || m) ~ LogicalOr(v || w))",
        parseTestExpression("u || m ~ v || w")
    );
}

unittest {
    assertEqual(
        "Range(u .. v)",
        parseTestExpression("u .. v")
    );
    assertEqual(
        "Range(u .. v)",
        parseTestExpression("u..v")
    );
    assertEqual(
        "Range(Range(u .. v) .. w)",
        parseTestExpression("u .. v .. w")
    );
    assertEqual(
        "Range(Concatenate(u ~ m) .. Concatenate(v ~ w))",
        parseTestExpression("u ~ m .. v ~ w")
    );
}

unittest {
    assertEqual(
        "Conditional(u if v else w)",
        parseTestExpression("u if v else w")
    );
    assertEqual(
        "Conditional(u if v else Conditional(w if x else y))",
        parseTestExpression("u if v else w if x else y")
    );
    assertEqual(
        "Conditional(Conditional(a if b else c) if Conditional(d if e else f) else Conditional(g if h else j))",
        parseTestExpression("(a if b else c) if (d if e else f) else (g if h else j)")
    );
    assertEqual(
        "Conditional(Range(a .. b) if Range(c .. d) else Range(e .. f))",
        parseTestExpression("a .. b if c .. d else e .. f")
    );
}

private string parseTestExpression(string source) {
    auto tokenizer = new Tokenizer(new DCharReader(source));
    if (tokenizer.head().getKind() == Kind.INDENTATION) {
        tokenizer.advance();
    }
    return parseExpression(tokenizer).toString();
}
