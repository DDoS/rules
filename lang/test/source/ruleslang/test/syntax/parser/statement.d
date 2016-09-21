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
        "VariableDeclaration(let Test t)",
        parse("let Test t")
    );
    assertEqual(
        "VariableDeclaration(let Test[] t)",
        parse("let Test[] t")
    );
    assertEqual(
        "VariableDeclaration(let Test t = Add(SignedIntegerLiteral(1) + SignedIntegerLiteral(1)))",
        parse("let Test t = 1 + 1")
    );
    assertEqual(
        "VariableDeclaration(let Test[] t = Add(SignedIntegerLiteral(1) + SignedIntegerLiteral(1)))",
        parse("let Test[] t = 1 + 1")
    );
    assertEqual(
        "VariableDeclaration(let t = Add(SignedIntegerLiteral(1) + SignedIntegerLiteral(1)))",
        parse("let t = 1 + 1")
    );
    assertParseFail("let");
    assertParseFail("let t");
    assertParseFail("let Test[]");
    assertEqual(
        "VariableDeclaration(var Test t)",
        parse("var Test t")
    );
    assertEqual(
        "VariableDeclaration(var Test[] t)",
        parse("var Test[] t")
    );
    assertEqual(
        "VariableDeclaration(var Test t = Add(SignedIntegerLiteral(1) + SignedIntegerLiteral(1)))",
        parse("var Test t = 1 + 1")
    );
    assertEqual(
        "VariableDeclaration(var Test[] t = Add(SignedIntegerLiteral(1) + SignedIntegerLiteral(1)))",
        parse("var Test[] t = 1 + 1")
    );
    assertEqual(
        "VariableDeclaration(var t = Add(SignedIntegerLiteral(1) + SignedIntegerLiteral(1)))",
        parse("var t = 1 + 1")
    );
    assertParseFail("var");
    assertParseFail("var t");
    assertParseFail("var Test[]");
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

private void assertParseFail(string source) {
    try {
        auto statements = parse(source);
        throw new AssertionError("Expected a source exception, but got statements:\n" ~ statements);
    } catch (SourceException exception) {
        debug (verboseTests) {
            import std.stdio : stderr;
            stderr.writeln(exception.getErrorInformation(source).toString());
        }
    }
}
