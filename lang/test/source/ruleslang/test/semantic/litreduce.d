module ruleslang.test.semantic.litreduce;

import ruleslang.syntax.dchars;
import ruleslang.syntax.source;
import ruleslang.syntax.tokenizer;
import ruleslang.syntax.parser.statement;
import ruleslang.semantic.litreduce;

import ruleslang.test.assertion;

unittest {
    assertEqual(
        "Assignment(a = IntegerLiteral(-1))",
        parseAndReduce("a = -1")
    );
    assertEqual(
        "Assignment(a = IntegerLiteral(1))",
        parseAndReduce("a = +1")
    );
    assertEqual(
        "Assignment(a = IntegerLiteral(1))",
        parseAndReduce("a = --1")
    );
    assertEqual(
        "Assignment(a = FloatLiteral(-1))",
        parseAndReduce("a = -1.0")
    );
    assertEqual(
        "Assignment(a = FloatLiteral(1.0))",
        parseAndReduce("a = +1.0")
    );
    assertEqual(
        "Assignment(a = FloatLiteral(1))",
        parseAndReduce("a = +-+--+---+++1.0")
    );
}

unittest {
    assertEqual(
        "Assignment(a = IntegerLiteral(-2))",
        parseAndReduce("a = ~1")
    );
    assertEqual(
        "Assignment(a = IntegerLiteral(1))",
        parseAndReduce("a = 1")
    );
    assertEqual(
        "Assignment(a = BitwiseNot(~FloatLiteral(1.0)))",
        parseAndReduce("a = ~1.0")
    );
}

unittest {
    assertEqual(
        "Assignment(a = IntegerLiteral(8))",
        parseAndReduce("a = 2 ** 3")
    );
    assertEqual(
        "Assignment(a = FloatLiteral(5.29))",
        parseAndReduce("a = 2.3 ** 2")
    );
    assertEqual(
        "Assignment(a = FloatLiteral(4.28709385))",
        parseAndReduce("a = 2 ** 2.1")
    );
    assertEqual(
        "Assignment(a = FloatLiteral(4.28709385))",
        parseAndReduce("a = 2.0 ** 2.1")
    );
}

unittest {
    assertEqual(
        "Assignment(a = IntegerLiteral(6))",
        parseAndReduce("a = 2 * 3")
    );
    assertEqual(
        "Assignment(a = FloatLiteral(2.3))",
        parseAndReduce("a = 4.6 / 2")
    );
    assertEqual(
        "Assignment(a = FloatLiteral(1.9))",
        parseAndReduce("a = 4 % 2.1")
    );
    assertEqual(
        "Assignment(a = FloatLiteral(4.2))",
        parseAndReduce("a = 2.0 * 2.1")
    );
}

unittest {
    assertEqual(
        "Assignment(a = IntegerLiteral(5))",
        parseAndReduce("a = 2 + 3")
    );
    assertEqual(
        "Assignment(a = FloatLiteral(0.3))",
        parseAndReduce("a = 2.3 - 2")
    );
    assertEqual(
        "Assignment(a = FloatLiteral(4.1))",
        parseAndReduce("a = 2 + 2.1")
    );
    assertEqual(
        "Assignment(a = FloatLiteral(-0.1))",
        parseAndReduce("a = 2.0 - 2.1")
    );
}

unittest {
    assertEqual(
        "Assignment(a = IntegerLiteral(8))",
        parseAndReduce("a = 1 << 3")
    );
    assertEqual(
        "Assignment(a = IntegerLiteral(-4))",
        parseAndReduce("a = -16 >> 2")
    );
    assertEqual(
        "Assignment(a = IntegerLiteral(4))",
        parseAndReduce("a = 16 >>> 2")
    );
    assertEqual(
        "Assignment(a = Shift(FloatLiteral(2.0) >> IntegerLiteral(1)))",
        parseAndReduce("a = 2.0 >> 1")
    );
}

unittest {
    assertEqual(
        "Assignment(a = IntegerLiteral(1))",
        parseAndReduce("a = 1 & 3")
    );
    assertEqual(
        "Assignment(a = BitwiseAnd(FloatLiteral(2.0) & IntegerLiteral(1)))",
        parseAndReduce("a = 2.0 & 1")
    );
}

unittest {
    assertEqual(
        "Assignment(a = IntegerLiteral(2))",
        parseAndReduce("a = 1 ^ 3")
    );
    assertEqual(
        "Assignment(a = BitwiseXor(FloatLiteral(2.0) ^ IntegerLiteral(1)))",
        parseAndReduce("a = 2.0 ^ 1")
    );
}

unittest {
    assertEqual(
        "Assignment(a = IntegerLiteral(7))",
        parseAndReduce("a = 4 | 3")
    );
    assertEqual(
        "Assignment(a = BitwiseOr(FloatLiteral(2.0) | IntegerLiteral(1)))",
        parseAndReduce("a = 2.0 | 1")
    );
}

unittest {
    assertEqual(
        "FunctionCall(a())",
        parseAndReduce("a()")
    );
}

private string parseAndReduce(string source) {
    auto statements = new Tokenizer(new DCharReader(source)).parseStatements();
    foreach (i, statement; statements) {
        statements[i] = statement.reduceLiterals();
    }
    return statements.join!"\n"();
}
