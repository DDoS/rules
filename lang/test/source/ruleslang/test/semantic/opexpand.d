module ruleslang.test.semantic.opexpand;

import ruleslang.syntax.source;
import ruleslang.syntax.tokenizer;
import ruleslang.syntax.parser.statement;
import ruleslang.semantic.opexpand;
import ruleslang.util;

import ruleslang.test.assertion;

unittest {
    assertEqual(
        "Assignment(a = FunctionCall(opReaffirm(b)))",
        parseAndExpand("a = +b")
    );
    assertEqual(
        "Assignment(a = FunctionCall(opReaffirm(UnsignedIntegerLiteral(1u))))",
        parseAndExpand("a = +1u")
    );
    assertEqual(
        "Assignment(a = Sign(+SignedIntegerLiteral(1)))",
        parseAndExpand("a = +1")
    );
    assertEqual(
        "Assignment(a = FunctionCall(opNegate(b)))",
        parseAndExpand("a = -b")
    );
    assertEqual(
        "Assignment(a = FunctionCall(opNegate(UnsignedIntegerLiteral(1u))))",
        parseAndExpand("a = -1u")
    );
    assertEqual(
        "Assignment(a = Sign(-SignedIntegerLiteral(1)))",
        parseAndExpand("a = -1")
    );
    assertEqual(
        "Assignment(a = FunctionCall(opLogicalNot(b)))",
        parseAndExpand("a = !b")
    );
    assertEqual(
        "Assignment(a = FunctionCall(opBitwiseNot(b)))",
        parseAndExpand("a = ~b")
    );
    assertEqual(
        "Assignment(a = FunctionCall(opExponent(a, b)))",
        parseAndExpand("a **= b")
    );
    assertEqual(
        "Assignment(a = FunctionCall(opMultiply(a, b)))",
        parseAndExpand("a *= b")
    );
    assertEqual(
        "Assignment(a = FunctionCall(opDivide(a, b)))",
        parseAndExpand("a /= b")
    );
    assertEqual(
        "Assignment(a = FunctionCall(opRemainder(a, b)))",
        parseAndExpand("a %= b")
    );
    assertEqual(
        "Assignment(a = FunctionCall(opAdd(a, b)))",
        parseAndExpand("a += b")
    );
    assertEqual(
        "Assignment(a = FunctionCall(opSubtract(a, b)))",
        parseAndExpand("a -= b")
    );
    assertEqual(
        "Assignment(a = FunctionCall(opLeftShift(a, b)))",
        parseAndExpand("a <<= b")
    );
    assertEqual(
        "Assignment(a = FunctionCall(opArithmeticRightShift(a, b)))",
        parseAndExpand("a >>= b")
    );
    assertEqual(
        "Assignment(a = FunctionCall(opLogicalRightShift(a, b)))",
        parseAndExpand("a >>>= b")
    );
    assertEqual(
        "Assignment(a = FunctionCall(opBitwiseAnd(a, b)))",
        parseAndExpand("a &= b")
    );
    assertEqual(
        "Assignment(a = FunctionCall(opBitwiseOr(a, b)))",
        parseAndExpand("a |= b")
    );
    assertEqual(
        "Assignment(a = FunctionCall(opBitwiseXor(a, b)))",
        parseAndExpand("a ^= b")
    );
    assertEqual(
        "Assignment(a = FunctionCall(opLogicalAnd(a, b)))",
        parseAndExpand("a &&= b")
    );
    assertEqual(
        "Assignment(a = FunctionCall(opLogicalOr(a, b)))",
        parseAndExpand("a ||= b")
    );
    assertEqual(
        "Assignment(a = FunctionCall(opLogicalXor(a, b)))",
        parseAndExpand("a ^^= b")
    );
    assertEqual(
        "Assignment(a = FunctionCall(opConcatenate(a, b)))",
        parseAndExpand("a ~= b")
    );
    assertEqual(
        "Assignment(a = Conditional(c if b else d))",
        parseAndExpand("a = c if b else d")
    );
}

unittest {
    assertEqual(
        "Assignment(a = FunctionCall(opGreaterThan(SignedIntegerLiteral(1), SignedIntegerLiteral(2))))",
        parseAndExpand("a = 1 > 2")
    );
    assertEqual(
        "Assignment(a = FunctionCall(opLogicalAnd(FunctionCall(opLogicalAnd(FunctionCall(opEquals(c, b)), "
            ~ "FunctionCall(opNotEquals(b, m)))), FunctionCall(opLesserThan(m, j)))))",
        parseAndExpand("a = c == b != m < j")
    );
    assertEqual(
        "Assignment(a = TypeCompare(a :: b))",
        parseAndExpand("a = a :: b")
    );
    assertEqual(
        "Assignment(a = FunctionCall(opLogicalAnd(ValueCompare(m === b), TypeCompare(b !: o))))",
        parseAndExpand("a = m === b !: o")
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
