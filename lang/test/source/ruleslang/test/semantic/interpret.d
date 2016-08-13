module ruleslang.test.semantic.interpret;

import ruleslang.syntax.source;
import ruleslang.syntax.token;
import ruleslang.syntax.tokenizer;
import ruleslang.syntax.parser.expression;
import ruleslang.semantic.opexpand;
import ruleslang.semantic.context;
import ruleslang.semantic.tree;
import ruleslang.util;

import ruleslang.test.assertion;

unittest {
    assertEqual(
        "IntegerLiteral(1) | int_lit(1)",
        interpret("+1")
    );
    assertEqual(
        "FunctionCall(opNegate(FloatLiteral(1))) | fp_lit(-1)",
        interpret("-1.0")
    );
    assertEqual(
        "FunctionCall(opBitwiseNot(IntegerLiteral(4294967295))) | int_lit(-4294967296)",
        interpret("0xFFFFFFFF.opBitwiseNot()")
    );
    assertEqual(
        "FunctionCall(opLogicalNot(BooleanLiteral(true))) | bool_lit(false)",
        interpret("!true")
    );
    assertEqual(
        "FunctionCall(opAdd(IntegerLiteral(1), IntegerLiteral(-3))) | int_lit(-2)",
        interpret("1 + -3")
    );
    assertEqual(
        "FunctionCall(opAdd(IntegerLiteral(1), IntegerLiteral(2))) | int_lit(3)",
        interpret("opAdd(1, 2)")
    );
    assertEqual(
        "FunctionCall(opAdd(IntegerLiteral(1), IntegerLiteral(2))) | int_lit(3)",
        interpret("1.opAdd(2)")
    );
    assertEqual(
        "FunctionCall(opAdd(IntegerLiteral(1), IntegerLiteral(2))) | int_lit(3)",
        interpret("1 opAdd 2")
    );
    assertEqual(
        "FunctionCall(opEquals(FunctionCall(opAdd(IntegerLiteral(1), IntegerLiteral(1))), IntegerLiteral(2)))"
            ~ " | bool_lit(true)",
        interpret("1 + 1 == 2")
    );
    assertInterpretFails("!1");
    assertInterpretFails("~true");
    assertInterpretFails("~1.");
    assertInterpretFails("lol");
    assertInterpretFails("1()");
    //assertInterpretFails("1.lol");
    assertInterpretFails("1.lol()");
    assertInterpretFails("1.opAdd()");
}

private string interpret(string source) {
    auto tokenizer = new Tokenizer(new DCharReader(source));
    if (tokenizer.head().getKind() == Kind.INDENTATION) {
        tokenizer.advance();
    }
    return tokenizer
            .parseExpression()
            .expandOperators()
            .interpret(new Context())
            .getInfo();
}

private void assertInterpretFails(string source) {
    try {
        auto node = source.interpret();
        throw new AssertionError("Expected a source exception, but got node:\n" ~ node);
    } catch (SourceException exception) {
        debug (verboseFails) {
            import std.stdio : stderr;
            stderr.writeln(exception.getErrorInformation(source).toString());
        }
    }
}

private string getInfo(immutable Node node) {
    string str = node.toString();
    auto typedNode = cast(immutable TypedNode) node;
    if (typedNode !is null) {
        str = str ~ " | " ~ typedNode.getType().toString();
    }
    return str;
}
