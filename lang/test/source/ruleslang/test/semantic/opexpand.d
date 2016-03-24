module ruleslang.test.semantic.opexpand;

import ruleslang.syntax.dcharstream;
import ruleslang.syntax.tokenizer;
import ruleslang.syntax.parser.statement;
import ruleslang.semantic.opexpand;

import ruleslang.test.assertion;

unittest {
    assertEqual(
        "Assignment(a = Exponent(a ** b))",
        parseAndExpand("a **= b")
    );
    assertEqual(
        "Assignment(a = Multiply(a * b))",
        parseAndExpand("a *= b")
    );
    assertEqual(
        "Assignment(a = Multiply(a / b))",
        parseAndExpand("a /= b")
    );
    assertEqual(
        "Assignment(a = Multiply(a % b))",
        parseAndExpand("a %= b")
    );
    assertEqual(
        "Assignment(a = Add(a + b))",
        parseAndExpand("a += b")
    );
    assertEqual(
        "Assignment(a = Add(a - b))",
        parseAndExpand("a -= b")
    );
    assertEqual(
        "Assignment(a = Shift(a << b))",
        parseAndExpand("a <<= b")
    );
    assertEqual(
        "Assignment(a = Shift(a >> b))",
        parseAndExpand("a >>= b")
    );
    assertEqual(
        "Assignment(a = Shift(a >>> b))",
        parseAndExpand("a >>>= b")
    );
    assertEqual(
        "Assignment(a = BitwiseAnd(a & b))",
        parseAndExpand("a &= b")
    );
    assertEqual(
        "Assignment(a = BitwiseOr(a | b))",
        parseAndExpand("a |= b")
    );
    assertEqual(
        "Assignment(a = BitwiseXor(a ^ b))",
        parseAndExpand("a ^= b")
    );
    assertEqual(
        "Assignment(a = LogicalAnd(a && b))",
        parseAndExpand("a &&= b")
    );
    assertEqual(
        "Assignment(a = LogicalOr(a || b))",
        parseAndExpand("a ||= b")
    );
    assertEqual(
        "Assignment(a = LogicalXor(a ^^ b))",
        parseAndExpand("a ^^= b")
    );
    assertEqual(
        "Assignment(a = Concatenate(a ~ b))",
        parseAndExpand("a ~= b")
    );
}

private string parseAndExpand(string source) {
    auto tokenizer = new Tokenizer(new DCharReader(new StringDCharStream(source)));
    return tokenizer.parseStatement().expandOperators().toString();
}
