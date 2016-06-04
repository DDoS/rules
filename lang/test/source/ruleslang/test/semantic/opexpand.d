module ruleslang.test.semantic.opexpand;

import ruleslang.syntax.source;
import ruleslang.syntax.tokenizer;
import ruleslang.syntax.parser.statement;
import ruleslang.semantic.opexpand;
import ruleslang.util;

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

unittest {
    assertEqual(
        "Assignment(a = ValueCompare(IntegerLiteral(1) > IntegerLiteral(2)))",
        parseAndExpand("a = 1 > 2")
    );
    assertEqual(
        "Assignment(a = LogicalAnd(LogicalAnd(ValueCompare(c == b) && ValueCompare(b != m)) && ValueCompare(m < j)))",
        parseAndExpand("a = c == b != m < j")
    );
    assertEqual(
        "Assignment(a = TypeCompare(a :: b))",
        parseAndExpand("a = a :: b")
    );
    assertEqual(
        "Assignment(a = LogicalAnd(ValueCompare(m == b) && TypeCompare(b !: o)))",
        parseAndExpand("a = m == b !: o")
    );
}

unittest {
    assertEqual(
        "Assignment(a = FunctionCall(c(b, d)))",
        parseAndExpand("a = b c d")
    );
    assertEqual(
        "Assignment(a = FunctionCall(e(FunctionCall(c(b, d)), f)))",
        parseAndExpand("a = b c d e f")
    );
}

unittest {
    assertEqual(
        "FunctionCall(a())",
        parseAndExpand("a()")
    );
}

private string parseAndExpand(string source) {
    auto statements = new Tokenizer(new DCharReader(source)).parseStatements();
    foreach (i, statement; statements) {
        statements[i] = statement.expandOperators();
    }
    return statements.join!"\n"();
}
