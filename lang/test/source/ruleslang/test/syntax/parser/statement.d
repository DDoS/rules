module ruleslang.test.syntax.parser.statement;

import ruleslang.syntax.dchars;
import ruleslang.syntax.dcharstream;
import ruleslang.syntax.tokenizer;
import ruleslang.syntax.ast.statement;
import ruleslang.syntax.parser.statement;

import ruleslang.test.assertion;

unittest {
    assertEqual(
        "Assignment(a = IntegerLiteral(1))",
        parse("a = 1")
    );
    assertEqual(
        "Assignment(a.b *= v)",
        parse("a.b *= v")
    );
    assertEqual(
        "Assignment(MemberAccess(FunctionCall(a.test()).field) ~= StringLiteral(\"2\"))",
        parse("a.test().field ~= \"2\"")
    );
    assertEqual(
        "InitializerAssignment(a = CompositeLiteral({a, b, CompositeLiteral({v})}))",
        parse("a = {a, b, {v}}")
    );
}

unittest {
    assertEqual(
        "FunctionCall(a())",
        parse("a()")
    );
    assertEqual(
        "FunctionCall(a(IntegerLiteral(1), b))",
        parse("a(1, b)")
    );
    assertEqual(
        "FunctionCall(a.b())",
        parse("a.b()")
    );
    assertEqual(
        "FunctionCall(MemberAccess(StringLiteral(\"test\").length)())",
        parse("\"test\".length()")
    );
    assertEqual(
        "FunctionCall(MemberAccess(Infix(IntegerLiteral(2) log b).test)())",
        parse("(2 log b).test()")
    );
}

unittest {
    assertEqual(
        "FunctionCall(a())\n" ~
            "Assignment(a = IntegerLiteral(1))\n" ~
            "FunctionCall(a.b())\n" ~
            "Assignment(a.b *= v)",
        parse("a()\na = 1; a.b();\n\t\ra.b *= v")
    );
}

private string parse(string source) {
    return new Tokenizer(new DCharReader(new StringDCharStream(source))).parseStatements().join!"\n"();
}
