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
        "FunctionCall(opAdd(FloatLiteral(1), FloatLiteral(2))) "
            ~ "| fp64",
        interpret("1u opAdd 2")
    );
    assertEqual(
        "FunctionCall(opAdd(FloatLiteral(1), FloatLiteral(2))) "
            ~ "| fp64",
        interpret("1 opAdd 2u")
    );
    assertEqual(
        "FunctionCall(opEquals(SignedIntegerLiteral(2), SignedIntegerLiteral(2))) | bool",
        interpret("1 + 1 == 2")
    );
    assertEqual(
        "FunctionCall(opLeftShift(SignedIntegerLiteral(1), UnsignedIntegerLiteral(2))) | sint64",
        interpret("1 << 2u")
    );
    assertEqual(
        "FunctionCall(opLeftShift(SignedIntegerLiteral(1), UnsignedIntegerLiteral(2))) | sint64",
        interpret("1 << 2")
    );
    assertEqual(
        "FunctionCall(opLeftShift(UnsignedIntegerLiteral(1), UnsignedIntegerLiteral(2))) | uint64",
        interpret("1u << '\\u2'")
    );
    assertEqual(
        "FunctionCall(sint8(SignedIntegerLiteral(257))) | sint8",
        interpret("sint8(257)")
    );
    assertEqual(
        "FunctionCall(uint8(FloatLiteral(1.2))) | uint8",
        interpret("uint8(1.2)")
    );
    assertEqual(
        "FunctionCall(fp32(FloatLiteral(-2.6))) | fp32",
        interpret("fp32(-2.6)")
    );
    assertEqual(
        "FunctionCall(fp32(SignedIntegerLiteral(-2))) | fp32",
        interpret("fp32(-2)")
    );
    assertEqual(
        "Conditional(BooleanLiteral(false), BooleanLiteral(false), BooleanLiteral(false)) | bool_lit(false)",
        interpret("false && false")
    );
    assertEqual(
        "Conditional(BooleanLiteral(false), BooleanLiteral(true), BooleanLiteral(false)) | bool",
        interpret("false && true")
    );
    assertEqual(
        "Conditional(BooleanLiteral(true), BooleanLiteral(false), BooleanLiteral(false)) | bool_lit(false)",
        interpret("true && false")
    );
    assertEqual(
        "Conditional(BooleanLiteral(true), BooleanLiteral(true), BooleanLiteral(false)) | bool",
        interpret("true && true")
    );
    assertEqual(
        "Conditional(BooleanLiteral(false), BooleanLiteral(true), BooleanLiteral(false)) | bool",
        interpret("false || false")
    );
    assertEqual(
        "Conditional(BooleanLiteral(false), BooleanLiteral(true), BooleanLiteral(true)) | bool_lit(true)",
        interpret("false || true")
    );
    assertEqual(
        "Conditional(BooleanLiteral(true), BooleanLiteral(true), BooleanLiteral(false)) | bool",
        interpret("true || false")
    );
    assertEqual(
        "Conditional(BooleanLiteral(true), BooleanLiteral(true), BooleanLiteral(true)) | bool_lit(true)",
        interpret("true || true")
    );
    assertEqual(
        "FunctionCall(opLogicalXor(BooleanLiteral(false), BooleanLiteral(false))) | bool",
        interpret("false ^^ false")
    );
    assertEqual(
        "FunctionCall(opLogicalXor(BooleanLiteral(false), BooleanLiteral(true))) | bool",
        interpret("false ^^ true")
    );
    assertEqual(
        "FunctionCall(opLogicalXor(BooleanLiteral(true), BooleanLiteral(false))) | bool",
        interpret("true ^^ false")
    );
    assertEqual(
        "FunctionCall(opLogicalXor(BooleanLiteral(true), BooleanLiteral(true))) | bool",
        interpret("true ^^ true")
    );
    assertEqual(
        "FunctionCall(len(ArrayLiteral({0: SignedIntegerLiteral(1)}))) | uint64",
        interpret("{0: 1}.len()")
    );
    assertEqual(
        "FunctionCall(len(ArrayLiteral({0: SignedIntegerLiteral(1)}))) | uint64",
        interpret("len({0: 1})")
    );
    assertEqual(
        "FunctionCall(len(ArrayLiteral({123: FloatLiteral(1), other: FloatLiteral(-2)}))) | uint64",
        interpret("len({123: 1, other: -2.0})")
    );
    assertEqual(
        "FunctionCall(len(StringLiteral(\"this is a test\"))) | uint64",
        interpret("\"this is a test\".len()")
    );
    assertEqual(
        "FunctionCall(len(ArrayLiteral({32: TupleLiteral({StringLiteral(\"no\")}), "
            ~ "other: TupleLiteral({StringLiteral(\"yes\")})}))) | uint64",
        interpret("len({32: {\"no\"}, other: {\"yes\"}})")
    );
    assertEqual(
        "FunctionCall(opConcatenate(StringLiteral(\"12\"), StringLiteral(\"1\"))) | uint32[]",
        interpret("\"12\" ~ \"1\"")
    );
    assertEqual(
        "FunctionCall(opConcatenate(StringLiteral(\"1\"), StringLiteral(\"12\"))) | uint32[]",
        interpret("\"1\" ~ \"12\"")
    );
    assertEqual(
        "FunctionCall(opConcatenate(StringLiteral(\"1\"), ArrayLiteral({0: UnsignedIntegerLiteral(97)}))) | uint32[]",
        interpret("\"1\" ~ {0: uint32('a')}")
    );
    assertEqual(
        "FunctionCall(opConcatenate(ArrayLiteral({0: UnsignedIntegerLiteral(97)}), StringLiteral(\"1\"))) | uint32[]",
        interpret("{0: uint32('a')} ~ \"1\"")
    );
    assertEqual(
        "FunctionCall(opConcatenate(ArrayLiteral({other: UnsignedIntegerLiteral(0)}), StringLiteral(\"1\"))) | uint32[]",
        interpret("{} ~ \"1\"")
    );
    assertInterpretFails("!1");
    assertInterpretFails("~true");
    assertInterpretFails("~1.");
    assertInterpretFails("lol");
    assertInterpretFails("1()");
    assertInterpretFails("1.lol");
    assertInterpretFails("1.lol()");
    assertInterpretFails("1.opAdd()");
    assertInterpretFails("1 && true");
    assertInterpretFails("true && 1");
    assertInterpretFails("1 || true");
    assertInterpretFails("true || 1");
    assertInterpretFails("1 ^^ true");
    assertInterpretFails("true ^^ 1");
    assertInterpretFails("1.len()");
    assertInterpretFails("{}.len()");
    assertInterpretFails("true.len()");
    assertInterpretFails("{0: uint16(49)} ~ \"b\"");
    assertInterpretFails("\"b\" ~ {0: uint16(49)}");
    assertInterpretFails("{0: 0, 0: 1}");
    assertInterpretFails("{0: 0, 1: 1, other: 2, other: 4}");
    assertInterpretFails("{s: 0, s: 1}");
}

unittest {
    assertInterpretFails("1[0]");
    assertEqual(
        "IndexAccess(StringLiteral(\"1\")[UnsignedIntegerLiteral(0)])) | uint32",
        interpret("\"1\"[0]")
    );
    assertInterpretFails("\"1\"[-1]");
    assertInterpretFails("\"1\"[2]");
    assertInterpretFails("\"1\"[0 + 0]");
    assertEqual(
        "IndexAccess(StringLiteral(\"1\")[UnsignedIntegerLiteral(0)])) | uint32",
        interpret("\"1\"[0u + 0u]")
    );
    assertEqual(
        "IndexAccess(TupleLiteral({SignedIntegerLiteral(0), FloatLiteral(1)})[UnsignedIntegerLiteral(0)]))"
            ~ " | sint_lit(0)",
        interpret("{0, 1.}[0]")
    );
    assertEqual(
        "IndexAccess(TupleLiteral({SignedIntegerLiteral(0), FloatLiteral(1)})[UnsignedIntegerLiteral(1)]))"
            ~ " | fp_lit(1)",
        interpret("{0, 1.}[1u]")
    );
    assertInterpretFails("{0, 1.}[2u]");
    assertEqual(
        "IndexAccess(TupleLiteral({SignedIntegerLiteral(0), FloatLiteral(1)})[UnsignedIntegerLiteral(1)]))"
            ~ " | fp_lit(1)",
        interpret("{0, 1.}[0u + 1u]")
    );
    assertEqual(
        "IndexAccess(ArrayLiteral({0: SignedIntegerLiteral(1), 1: SignedIntegerLiteral(2)})["
            ~ "UnsignedIntegerLiteral(0)])) | sint64",
        interpret("{0: 1, 1: 2}[0u]")
    );
    assertEqual(
        "IndexAccess(ArrayLiteral({0: SignedIntegerLiteral(1), 1: SignedIntegerLiteral(2)})["
            ~ "UnsignedIntegerLiteral(1)])) | sint64",
        interpret("{0: 1, 1: 2}[1u]")
    );
    assertInterpretFails("{0: 1, 1: 2}[2u]");
    assertEqual(
        "IndexAccess(ArrayLiteral({0: SignedIntegerLiteral(1), 1: SignedIntegerLiteral(2)})["
            ~ "UnsignedIntegerLiteral(0)])) | sint64",
        interpret("{0: 1, 1: 2}[0u + 0u]")
    );
    assertEqual(
        "IndexAccess(ArrayLiteral({0: FloatLiteral(1), 1: FloatLiteral(2.2)})["
            ~ "UnsignedIntegerLiteral(0)])) | fp64",
        interpret("{0: 1, 1: 2.2}[0u + 0u]")
    );
    assertInterpretFails("{}[0]");
    assertInterpretFails("{0: 1, 2: 3.0, 6: \"yesy\", other: {true}}");
}

unittest {
    assertInterpretFails("{0: true, 1: 0}");
    assertEqual(
        "ArrayLiteral({0: BooleanLiteral(true), 1: BooleanLiteral(true)})"
            ~ " | bool_lit(true)[2]",
        interpret("{0: true, 1: true}")
    );
    assertEqual(
        "ArrayLiteral({0: BooleanLiteral(true), 1: BooleanLiteral(false)})"
            ~ " | bool[2]",
        interpret("{0: true, 1: false}")
    );
    assertEqual(
        "ArrayLiteral({0: FloatLiteral(1), 1: FloatLiteral(2)})"
            ~ " | fp64[2]",
        interpret("{0: 1, 1: 2.0}")
    );
    assertEqual(
        "ArrayLiteral({0: FloatLiteral(1), 1: FloatLiteral(1)})"
            ~ " | fp_lit(1)[2]",
        interpret("{0: 1, 1: 1.0}")
    );
    assertEqual(
        "ArrayLiteral({0: SignedIntegerLiteral(1), 1: SignedIntegerLiteral(1)})"
            ~ " | sint_lit(1)[2]",
        interpret("{0: 1, 1: 1}")
    );
    assertEqual(
        "ArrayLiteral({0: SignedIntegerLiteral(1), 1: SignedIntegerLiteral(2)})"
            ~ " | sint64[2]",
        interpret("{0: 1, 1: 2}")
    );
    assertEqual(
        "ArrayLiteral({0: SignedIntegerLiteral(1), 1: SignedIntegerLiteral(-1)})"
            ~ " | sint64[2]",
        interpret("{0: 1, 1: -1}")
    );
    assertEqual(
        "ArrayLiteral({1: TupleLiteral({SignedIntegerLiteral(1), SignedIntegerLiteral(2)}),"
            ~ " 0: TupleLiteral({SignedIntegerLiteral(1), SignedIntegerLiteral(2), SignedIntegerLiteral(3)})})"
            ~ " | {sint_lit(1), sint_lit(2)}[2]",
        interpret("{1: {1, 2}, 0: {1, 2, 3}}")
    );
    assertEqual(
        "ArrayLiteral({1: TupleLiteral({SignedIntegerLiteral(1), SignedIntegerLiteral(2), BooleanLiteral(true)}), "
            ~ "0: TupleLiteral({SignedIntegerLiteral(1), SignedIntegerLiteral(2), SignedIntegerLiteral(3)})})"
            ~ " | {sint_lit(1), sint_lit(2)}[2]",
        interpret("{1: {1, 2, true}, 0: {1, 2, 3}}")
    );
    assertEqual(
        "ArrayLiteral({1: TupleLiteral({SignedIntegerLiteral(1), SignedIntegerLiteral(2)}), "
            ~ "0: StructLiteral({a: SignedIntegerLiteral(1), b: SignedIntegerLiteral(2), c: SignedIntegerLiteral(3)})})"
            ~ " | {sint_lit(1), sint_lit(2)}[2]",
        interpret("{1: {1, 2}, 0: {a: 1, b: 2, c: 3}}")
    );
    assertEqual(
        "ArrayLiteral({1: TupleLiteral({SignedIntegerLiteral(1), SignedIntegerLiteral(2)}), "
            ~ "0: ArrayLiteral({0: SignedIntegerLiteral(1), 1: SignedIntegerLiteral(2), 2: SignedIntegerLiteral(3)})})"
            ~ " | {}[2]",
        interpret("{1: {1, 2}, 0: {0: 1, 1: 2, 2: 3}}")
    );
    assertEqual(
        "ArrayLiteral({1: TupleLiteral({SignedIntegerLiteral(1), SignedIntegerLiteral(1), SignedIntegerLiteral(2)}), "
            ~ "0: ArrayLiteral({0: SignedIntegerLiteral(1), 1: SignedIntegerLiteral(1), 2: SignedIntegerLiteral(1)})})"
            ~ " | {}[2]",
        interpret("{1: {1, 1, 2}, 0: {0: 1, 1: 1, 2: 1}}")
    );
    assertEqual(
        "ArrayLiteral({0: StructLiteral({a: SignedIntegerLiteral(1), b: SignedIntegerLiteral(2)}), "
            ~ "1: ArrayLiteral({0: SignedIntegerLiteral(1), 1: SignedIntegerLiteral(2)})})"
            ~ " | {}[2]",
        interpret("{0: {a: 1, b: 2}, 1: {0: 1, 1: 2}}")
    );
    assertEqual(
        "ArrayLiteral({0: StructLiteral({a: SignedIntegerLiteral(1), b: SignedIntegerLiteral(1), c: SignedIntegerLiteral(1)}), "
            ~ "1: StructLiteral({a: SignedIntegerLiteral(1), b: SignedIntegerLiteral(1)})})"
            ~ " | {sint_lit(1) a, sint_lit(1) b}[2]",
        interpret("{0: {a: 1, b: 1, c: 1}, 1: {a: 1, b: 1}}")
    );
    assertEqual(
        "ArrayLiteral({0: StructLiteral({a: SignedIntegerLiteral(1), b: SignedIntegerLiteral(1), c: SignedIntegerLiteral(1)}), "
            ~ "1: StructLiteral({a: SignedIntegerLiteral(1), b: SignedIntegerLiteral(1), c: SignedIntegerLiteral(1)})})"
            ~ " | {sint_lit(1) a, sint_lit(1) b, sint_lit(1) c}[2]",
        interpret("{0: {a: 1, b: 1, c: 1}, 1: {a: 1, b: 1, c: 1}}")
    );
    assertEqual(
        "ArrayLiteral({0: StructLiteral({a: SignedIntegerLiteral(1), b: SignedIntegerLiteral(1), c: SignedIntegerLiteral(2)}), "
            ~ "1: StructLiteral({a: SignedIntegerLiteral(1), b: SignedIntegerLiteral(1), c: SignedIntegerLiteral(1)})})"
            ~ " | {sint_lit(1) a, sint_lit(1) b}[2]",
        interpret("{0: {a: 1, b: 1, c: 2}, 1: {a: 1, b: 1, c: 1}}")
    );
    assertEqual(
        "ArrayLiteral({0: StructLiteral({a: SignedIntegerLiteral(1), b: SignedIntegerLiteral(2), c: SignedIntegerLiteral(1)}), "
            ~ "1: StructLiteral({a: SignedIntegerLiteral(1), b: SignedIntegerLiteral(1), c: SignedIntegerLiteral(1)})})"
            ~ " | {sint_lit(1) a, sint_lit(1) c}[2]",
        interpret("{0: {a: 1, b: 2, c: 1}, 1: {a: 1, b: 1, c: 1}}")
    );
    assertEqual(
        "ArrayLiteral({0: StructLiteral({a: SignedIntegerLiteral(1), b: SignedIntegerLiteral(2), c: SignedIntegerLiteral(3)}), "
            ~ "1: TupleLiteral({SignedIntegerLiteral(1), SignedIntegerLiteral(2), SignedIntegerLiteral(3)})})"
            ~ " | {sint_lit(1), sint_lit(2), sint_lit(3)}[2]",
        interpret("{0: {a: 1, b: 2, c: 3}, 1: {1, 2, 3}}")
    );
    assertEqual(
        "ArrayLiteral({0: StructLiteral({a: SignedIntegerLiteral(1), b: SignedIntegerLiteral(2), c: SignedIntegerLiteral(3)}), "
            ~ "1: TupleLiteral({SignedIntegerLiteral(1), SignedIntegerLiteral(2)})})"
            ~ " | {sint_lit(1), sint_lit(2)}[2]",
        interpret("{0: {a: 1, b: 2, c: 3}, 1: {1, 2}}")
    );
    assertEqual(
        "ArrayLiteral({0: StructLiteral({a: SignedIntegerLiteral(1), b: SignedIntegerLiteral(2), c: SignedIntegerLiteral(3)}), "
            ~ "1: TupleLiteral({SignedIntegerLiteral(1), SignedIntegerLiteral(2), SignedIntegerLiteral(3), "
            ~ "SignedIntegerLiteral(4)})})"
            ~ " | {sint_lit(1), sint_lit(2), sint_lit(3)}[2]",
        interpret("{0: {a: 1, b: 1 + 1, c: 3}, 1: {1, 2, 3, 4}}")
    );
    assertEqual(
        "ArrayLiteral({0: EmptyLiteralNode({}), 1: TupleLiteral({BooleanLiteral(true)})})"
            ~ " | {}[2]",
        interpret("{0: {}, 1: {true}}")
    );
    assertEqual(
        "ArrayLiteral({0: EmptyLiteralNode({}), 1: StructLiteral({b: BooleanLiteral(true)})})"
            ~ " | {}[2]",
        interpret("{0: {}, 1: {b: true}}")
    );
    assertEqual(
        "ArrayLiteral({0: ArrayLiteral({0: SignedIntegerLiteral(1), 1: SignedIntegerLiteral(2)}), "
            ~ "1: TupleLiteral({SignedIntegerLiteral(1), SignedIntegerLiteral(2)})})"
            ~ " | {}[2]",
        interpret("{0: {0: 1, 1: 2}, 1: {1, 2}}")
    );
    assertEqual(
        "ArrayLiteral({0: ArrayLiteral({0: SignedIntegerLiteral(1), 1: SignedIntegerLiteral(1)}), "
            ~ "1: TupleLiteral({SignedIntegerLiteral(1), SignedIntegerLiteral(1)})})"
            ~ " | {}[2]",
        interpret("{0: {0: 1, 1: 1}, 1: {1, 1}}")
    );
    assertEqual(
        "ArrayLiteral({0: StringLiteral(\"hello\"), 1: StringLiteral(\"hello\")})"
            ~ " | string_lit(\"hello\")[2]",
        interpret("{0: \"hello\", 1: \"hello\"}")
    );
    assertEqual(
        "ArrayLiteral({0: StringLiteral(\"hello\"), 1: StringLiteral(\"hell\")})"
            ~ " | string_lit(\"hell\")[2]",
        interpret("{0: \"hello\", 1: \"hell\"}")
    );
    assertEqual(
        "ArrayLiteral({0: StringLiteral(\"hello\"), 1: StringLiteral(\"allo\")})"
            ~ " | string_lit(\"\")[2]",
        interpret("{0: \"hello\", 1: \"allo\"}")
    );
    assertEqual(
        "ArrayLiteral({0: StringLiteral(\"allo\"), 1: StringLiteral(\"hello\")})"
            ~ " | string_lit(\"\")[2]",
        interpret("{0: \"allo\", 1: \"hello\"}")
    );
    assertEqual(
        "ArrayLiteral({0: StringLiteral(\"hello\"), 1: TupleLiteral({SignedIntegerLiteral(1), SignedIntegerLiteral(1)})})"
            ~ " | {}[2]",
        interpret("{0: \"hello\", 1: {1, 1}}")
    );
}

unittest {
    assertEqual(
        "Conditional(BooleanLiteral(true), FloatLiteral(1), FloatLiteral(1)) | fp_lit(1)",
        interpret("1 if true else 1.0")
    );
    assertEqual(
        "Conditional(BooleanLiteral(true), FloatLiteral(1), FloatLiteral(-1)) | fp64",
        interpret("1 if true else -1.0")
    );
    assertEqual(
        "Conditional(BooleanLiteral(false), FloatLiteral(2), FloatLiteral(2)) | fp64",
        interpret("2 if false else 2u")
    );
    assertEqual(
        "Conditional(BooleanLiteral(false), FloatLiteral(-2), FloatLiteral(2)) | fp64",
        interpret("-2 if false else 2u")
    );
    assertEqual(
        "Conditional(BooleanLiteral(false), StringLiteral(\"hello\"), StringLiteral(\"hell\")) | string_lit(\"hell\")",
        interpret("\"hello\" if false else \"hell\"")
    );
    assertEqual(
        "Conditional(BooleanLiteral(false), StringLiteral(\"allo\"), StringLiteral(\"hello\")) | string_lit(\"\")",
        interpret("\"allo\" if false else \"hello\"")
    );
    assertEqual(
        "Conditional(BooleanLiteral(false), "
            ~ "TupleLiteral({SignedIntegerLiteral(1), SignedIntegerLiteral(2), BooleanLiteral(true)}), "
            ~ "TupleLiteral({SignedIntegerLiteral(1), SignedIntegerLiteral(2), SignedIntegerLiteral(3)})) "
            ~ "| {sint_lit(1), sint_lit(2)}",
        interpret("{1, 2, true} if false else {1, 2, 3}")
    );
    assertInterpretFails("false if true else 2");
    assertInterpretFails("{} if true else 2");
    assertInterpretFails("2 if \"lol\" else 2");
}

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
