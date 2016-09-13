module ruleslang.test.syntax.parser.statement;

import ruleslang.syntax.source;
import ruleslang.syntax.tokenizer;
import ruleslang.syntax.ast.statement;
import ruleslang.syntax.parser.statement;
import ruleslang.util;

import ruleslang.test.assertion;

unittest {
    assertEqual(
        "TypeDefinition(def test: lol)",
        parse("def test: lol")
    );
    assertEqual(
        "TypeDefinition(def Vec2d: {fp64 x, fp64 y})",
        parse("def Vec2d: {fp64 x, fp64 y}")
    );
}

unittest {
    assertEqual(
        "Assignment(a = SignedIntegerLiteral(1))",
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
        "Assignment(a = CompositeLiteral({a, b, CompositeLiteral({v})}))",
        parse("a = {a, b, {v}}")
    );
    assertEqual(
        "Assignment(a = Initializer(test[]{SignedIntegerLiteral(1), StringLiteral(\"2\"),"
                ~ " CompositeLiteral({hey: FloatLiteral(2.1)})}))",
        parse("a = test[] {1, \"2\", {hey: 2.1}}")
    );
}

unittest {
    assertEqual(
        "FunctionCall(a())",
        parse("a()")
    );
    assertEqual(
        "FunctionCall(a(SignedIntegerLiteral(1), b))",
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
        "FunctionCall(MemberAccess(Infix(SignedIntegerLiteral(2) log b).test)())",
        parse("(2 log b).test()")
    );
}

unittest {
    assertEqual(
        "FunctionCall(a())\n" ~
            "Assignment(a = SignedIntegerLiteral(1))\n" ~
            "FunctionCall(a.b())\n" ~
            "Assignment(a.b *= v)",
        parse("a()\na = 1; a.b();\n\t\ra.b *= v")
    );
}

private string parse(string source) {
    return new Tokenizer(new DCharReader(source)).parseStatements().join!"\n"();
}
