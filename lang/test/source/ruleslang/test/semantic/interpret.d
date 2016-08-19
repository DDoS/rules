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
        "FunctionCall(opNegate(FloatLiteral(1))) | fp64",
        interpret("-1.0")
    );
    assertEqual(
        "FunctionCall(opBitwiseNot(SignedIntegerLiteral(4294967295))) | sint64",
        interpret("0xFFFFFFFF.opBitwiseNot()")
    );
    assertEqual(
        "FunctionCall(opLogicalNot(BooleanLiteral(true))) | bool",
        interpret("!true")
    );
    assertEqual(
        "FunctionCall(opAdd(SignedIntegerLiteral(1), SignedIntegerLiteral(-3))) | sint64",
        interpret("1 + -3")
    );
    assertEqual(
        "FunctionCall(opAdd(SignedIntegerLiteral(1), SignedIntegerLiteral(2))) | sint64",
        interpret("opAdd(1, 2)")
    );
    assertEqual(
        "FunctionCall(opAdd(SignedIntegerLiteral(1), SignedIntegerLiteral(2))) | sint64",
        interpret("1.opAdd(2)")
    );
    assertEqual(
        "FunctionCall(opAdd(UnsignedIntegerLiteral(1), UnsignedIntegerLiteral(2))) | uint64",
        interpret("1u opAdd 2u")
    );
    assertEqual(
        "FunctionCall(opAdd(UnsignedIntegerLiteral(1), SignedIntegerLiteral(2))) | fp64",
        interpret("1u opAdd 2")
    );
    assertEqual(
        "FunctionCall(opEquals(FunctionCall(opAdd(SignedIntegerLiteral(1), SignedIntegerLiteral(1))), SignedIntegerLiteral(2)))"
            ~ " | bool",
        interpret("1 + 1 == 2")
    );
    assertEqual(
        "FunctionCall(opLeftShift(SignedIntegerLiteral(1), UnsignedIntegerLiteral(2))) | sint64",
        interpret("1 << 2u")
    );
    assertEqual(
        "FunctionCall(opLeftShift(UnsignedIntegerLiteral(1), UnsignedIntegerLiteral(2))) | uint64",
        interpret("1u << '\\u2'")
    );
    assertInterpretFails("!1");
    assertInterpretFails("~true");
    assertInterpretFails("~1.");
    assertInterpretFails("lol");
    assertInterpretFails("1()");
    assertInterpretFails("1.lol");
    assertInterpretFails("1.lol()");
    assertInterpretFails("1.opAdd()");
    assertInterpretFails("1 << 2");
}

unittest {
    assertInterpretFails("{0: true, 1: 0}");
    assertEqual(
        "bool_lit(true)[2]",
        type("{0: true, 1: true}")
    );
    assertEqual(
        "bool[2]",
        type("{0: true, 1: false}")
    );
    assertEqual(
        "fp64[2]",
        type("{0: 1, 1: 2.0}")
    );
    assertEqual(
        "fp_lit(1)[2]",
        type("{0: 1, 1: 1.0}")
    );
    assertEqual(
        "sint_lit(1)[2]",
        type("{0: 1, 1: 1}")
    );
    assertEqual(
        "sint64[2]",
        type("{0: 1, 1: 2}")
    );
    assertEqual(
        "sint64[2]",
        type("{0: 1, 1: -1}")
    );
    assertEqual(
        "{sint_lit(1), sint_lit(2)}[2]",
        type("{1: {1, 2}, 0: {1, 2, 3}}")
    );
    assertEqual(
        "{sint_lit(1), sint_lit(2)}[2]",
        type("{1: {1, 2, true}, 0: {1, 2, 3}}")
    );
    assertEqual(
        "{sint_lit(1), sint_lit(2)}[2]",
        type("{1: {1, 2}, 0: {a: 1, b: 2, c: 3}}")
    );
    assertEqual(
        "{}[2]",
        type("{1: {1, 2}, 0: {0: 1, 1: 2, 2: 3}}")
    );
    assertEqual(
        "{sint_lit(1), sint_lit(1)}[2]",
        type("{1: {1, 1, 2}, 0: {0: 1, 1: 1, 2: 1}}")
    );
    assertEqual(
        "{}[2]",
        type("{0: {a: 1, b: 2}, 1: {0: 1, 1: 2}}")
    );
    assertEqual(
        "{sint_lit(1) a, sint_lit(1) b}[2]",
        type("{0: {a: 1, b: 1, c: 1}, 1: {a: 1, b: 1}}")
    );
    assertEqual(
        "{sint_lit(1) a, sint_lit(1) b, sint_lit(1) c}[2]",
        type("{0: {a: 1, b: 1, c: 1}, 1: {a: 1, b: 1, c: 1}}")
    );
    assertEqual(
        "{sint_lit(1) a, sint_lit(1) b}[2]",
        type("{0: {a: 1, b: 1, c: 2}, 1: {a: 1, b: 1, c: 1}}")
    );
    assertEqual(
        "{sint_lit(1) a, sint_lit(1) c}[2]",
        type("{0: {a: 1, b: 2, c: 1}, 1: {a: 1, b: 1, c: 1}}")
    );
    assertEqual(
        "{sint_lit(1), sint_lit(2), sint_lit(3)}[2]",
        type("{0: {a: 1, b: 2, c: 3}, 1: {1, 2, 3}}")
    );
    assertEqual(
        "{sint_lit(1), sint_lit(2)}[2]",
        type("{0: {a: 1, b: 2, c: 3}, 1: {1, 2}}")
    );
    assertEqual(
        "{sint_lit(1) a, sint_lit(2) b, sint_lit(3) c}[2]",
        type("{0: {a: 1, b: 2, c: 3}, 1: {1, 2, 3, 4}}")
    );
    assertEqual(
        "{}[2]",
        type("{0: {}, 1: {true}}")
    );
    assertEqual(
        "{}[2]",
        type("{0: {}, 1: {b: true}}")
    );
    assertEqual(
        "{}[2]",
        type("{0: {0: 1, 1: 2}, 1: {1, 2}}")
    );
    assertEqual(
        "sint_lit(1)[2][2]",
        type("{0: {0: 1, 1: 1}, 1: {1, 1}}")
    );
    assertEqual(
        "string_lit(\"hello\")[2]",
        type("{0: \"hello\", 1: \"hello\"}")
    );
    assertEqual(
        "string_lit(\"hell\")[2]",
        type("{0: \"hello\", 1: \"hell\"}")
    );
    assertEqual(
        "uint32[4][2]",
        type("{0: \"hello\", 1: \"allo\"}")
    );
    assertEqual(
        "uint32[4][2]",
        type("{0: \"allo\", 1: \"hello\"}")
    );
    assertEqual(
        "{}[2]",
        type("{0: \"hello\", 1: {1, 1}}")
    );
}

private alias type = interpret!getTypeInfo;

private string interpret(alias info = getAllInfo)(string source) {
    auto tokenizer = new Tokenizer(new DCharReader(source));
    if (tokenizer.head().getKind() == Kind.INDENTATION) {
        tokenizer.advance();
    }
    return info(tokenizer.parseExpression().expandOperators().interpret(new Context()));
}

private void assertInterpretFails(string source) {
    try {
        auto node = source.interpret();
        throw new AssertionError("Expected a source exception, but got node:\n" ~ node);
    } catch (SourceException exception) {
        debug (verboseTests) {
            import std.stdio : stderr;
            stderr.writeln(exception.getErrorInformation(source).toString());
        }
    }
}

private string getTreeInfo(immutable Node node) {
    return node.toString();
}

private string getTypeInfo(immutable Node node) {
    auto typedNode = cast(immutable TypedNode) node;
    if (typedNode !is null) {
        return typedNode.getType().toString();
    }
    return "";
}

private string getAllInfo(immutable Node node) {
    string nodeInfo = node.getTreeInfo();
    string typeInfo = node.getTypeInfo();
    if (typeInfo.length > 0) {
        nodeInfo = nodeInfo ~ " | " ~ typeInfo;
    }
    return nodeInfo;
}
