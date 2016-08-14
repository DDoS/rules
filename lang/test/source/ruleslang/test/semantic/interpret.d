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
        "SignedIntegerLiteral(1) | sint_lit(1)",
        interpret("+1")
    );
    assertEqual(
        "FunctionCall(opNegate(FloatLiteral(1))) | fp_lit(-1)",
        interpret("-1.0")
    );
    assertEqual(
        "FunctionCall(opBitwiseNot(SignedIntegerLiteral(4294967295))) | sint_lit(-4294967296)",
        interpret("0xFFFFFFFF.opBitwiseNot()")
    );
    assertEqual(
        "FunctionCall(opLogicalNot(BooleanLiteral(true))) | bool_lit(false)",
        interpret("!true")
    );
    assertEqual(
        "FunctionCall(opAdd(SignedIntegerLiteral(1), SignedIntegerLiteral(-3))) | sint_lit(-2)",
        interpret("1 + -3")
    );
    assertEqual(
        "FunctionCall(opAdd(SignedIntegerLiteral(1), SignedIntegerLiteral(2))) | sint_lit(3)",
        interpret("opAdd(1, 2)")
    );
    assertEqual(
        "FunctionCall(opAdd(SignedIntegerLiteral(1), SignedIntegerLiteral(2))) | sint_lit(3)",
        interpret("1.opAdd(2)")
    );
    assertEqual(
        "FunctionCall(opAdd(UnsignedIntegerLiteral(1), UnsignedIntegerLiteral(2))) | uint_lit(3)",
        interpret("1u opAdd 2u")
    );
    assertEqual(
        "FunctionCall(opAdd(UnsignedIntegerLiteral(1), SignedIntegerLiteral(2))) | fp_lit(3)",
        interpret("1u opAdd 2")
    );
    assertEqual(
        "FunctionCall(opEquals(FunctionCall(opAdd(SignedIntegerLiteral(1), SignedIntegerLiteral(1))), SignedIntegerLiteral(2)))"
            ~ " | bool_lit(true)",
        interpret("1 + 1 == 2")
    );
    assertEqual(
        "FunctionCall(opLeftShift(SignedIntegerLiteral(1), UnsignedIntegerLiteral(2))) | sint_lit(4)",
        interpret("1 << 2u")
    );
    assertEqual(
        "FunctionCall(opLeftShift(UnsignedIntegerLiteral(1), UnsignedIntegerLiteral(2))) | uint_lit(4)",
        interpret("1u << '\\u2'")
    );
    assertInterpretFails("!1");
    assertInterpretFails("~true");
    assertInterpretFails("~1.");
    assertInterpretFails("lol");
    assertInterpretFails("1()");
    //assertInterpretFails("1.lol");
    assertInterpretFails("1.lol()");
    assertInterpretFails("1.opAdd()");
    assertInterpretFails("1 << 2");
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
