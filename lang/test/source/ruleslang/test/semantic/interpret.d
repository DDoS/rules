module ruleslang.test.semantic.interpret;

import ruleslang.syntax.source;
import ruleslang.syntax.token;
import ruleslang.syntax.tokenizer;
import ruleslang.syntax.parser.statement;
import ruleslang.syntax.parser.expression;
import ruleslang.semantic.opexpand;
import ruleslang.semantic.context;
import ruleslang.semantic.tree;
import ruleslang.util;

import ruleslang.test.assertion;

unittest {
    assertEqual(
        "NullLiteral(null) | null",
        interpretExp("null")
    );
    assertEqual(
        "SignedIntegerLiteral(1) | sint64_lit(1)",
        interpretExp("+1")
    );
    assertEqual(
        "FunctionCall(opNegate(FloatLiteral(1))) | fp64",
        interpretExp("-1.0")
    );
    assertEqual(
        "FunctionCall(opBitwiseNot(SignedIntegerLiteral(4294967295))) | sint64",
        interpretExp("0xFFFFFFFF.opBitwiseNot()")
    );
    assertEqual(
        "FunctionCall(opLogicalNot(BooleanLiteral(true))) | bool",
        interpretExp("!true")
    );
    assertEqual(
        "FunctionCall(opAdd(SignedIntegerLiteral(1), SignedIntegerLiteral(-3))) | sint64",
        interpretExp("1 + -3")
    );
    assertEqual(
        "FunctionCall(opAdd(SignedIntegerLiteral(1), SignedIntegerLiteral(2))) | sint64",
        interpretExp("opAdd(1, 2)")
    );
    assertEqual(
        "FunctionCall(opAdd(SignedIntegerLiteral(1), SignedIntegerLiteral(2))) | sint64",
        interpretExp("1.opAdd(2)")
    );
    assertEqual(
        "FunctionCall(opAdd(UnsignedIntegerLiteral(1), UnsignedIntegerLiteral(2))) | uint64",
        interpretExp("1u opAdd 2u")
    );
    assertEqual(
        "FunctionCall(opAdd(FloatLiteral(1), FloatLiteral(2))) "
            ~ "| fp64",
        interpretExp("1u opAdd 2")
    );
    assertEqual(
        "FunctionCall(opAdd(FloatLiteral(1), FloatLiteral(2))) "
            ~ "| fp64",
        interpretExp("1 opAdd 2u")
    );
    assertEqual(
        "FunctionCall(opEquals(SignedIntegerLiteral(2), SignedIntegerLiteral(2))) | bool",
        interpretExp("1 + 1 == 2")
    );
    assertEqual(
        "FunctionCall(opLeftShift(SignedIntegerLiteral(1), UnsignedIntegerLiteral(2))) | sint64",
        interpretExp("1 << 2u")
    );
    assertEqual(
        "FunctionCall(opLeftShift(SignedIntegerLiteral(1), UnsignedIntegerLiteral(2))) | sint64",
        interpretExp("1 << 2")
    );
    assertEqual(
        "FunctionCall(opLeftShift(UnsignedIntegerLiteral(1), UnsignedIntegerLiteral(2))) | uint64",
        interpretExp("1u << '\\u2'")
    );
    assertEqual(
        "FunctionCall(sint8(SignedIntegerLiteral(257))) | sint8",
        interpretExp("sint8(257)")
    );
    assertEqual(
        "FunctionCall(uint8(FloatLiteral(1.2))) | uint8",
        interpretExp("uint8(1.2)")
    );
    assertEqual(
        "FunctionCall(fp32(FloatLiteral(-2.6))) | fp32",
        interpretExp("fp32(-2.6)")
    );
    assertEqual(
        "FunctionCall(fp32(SignedIntegerLiteral(-2))) | fp32",
        interpretExp("fp32(-2)")
    );
    assertEqual(
        "Conditional(BooleanLiteral(false), BooleanLiteral(false), BooleanLiteral(false)) | bool_lit(false)",
        interpretExp("false && false")
    );
    assertEqual(
        "Conditional(BooleanLiteral(false), BooleanLiteral(true), BooleanLiteral(false)) | bool",
        interpretExp("false && true")
    );
    assertEqual(
        "Conditional(BooleanLiteral(true), BooleanLiteral(false), BooleanLiteral(false)) | bool_lit(false)",
        interpretExp("true && false")
    );
    assertEqual(
        "Conditional(BooleanLiteral(true), BooleanLiteral(true), BooleanLiteral(false)) | bool",
        interpretExp("true && true")
    );
    assertEqual(
        "Conditional(BooleanLiteral(false), BooleanLiteral(true), BooleanLiteral(false)) | bool",
        interpretExp("false || false")
    );
    assertEqual(
        "Conditional(BooleanLiteral(false), BooleanLiteral(true), BooleanLiteral(true)) | bool_lit(true)",
        interpretExp("false || true")
    );
    assertEqual(
        "Conditional(BooleanLiteral(true), BooleanLiteral(true), BooleanLiteral(false)) | bool",
        interpretExp("true || false")
    );
    assertEqual(
        "Conditional(BooleanLiteral(true), BooleanLiteral(true), BooleanLiteral(true)) | bool_lit(true)",
        interpretExp("true || true")
    );
    assertEqual(
        "FunctionCall(opLogicalXor(BooleanLiteral(false), BooleanLiteral(false))) | bool",
        interpretExp("false ^^ false")
    );
    assertEqual(
        "FunctionCall(opLogicalXor(BooleanLiteral(false), BooleanLiteral(true))) | bool",
        interpretExp("false ^^ true")
    );
    assertEqual(
        "FunctionCall(opLogicalXor(BooleanLiteral(true), BooleanLiteral(false))) | bool",
        interpretExp("true ^^ false")
    );
    assertEqual(
        "FunctionCall(opLogicalXor(BooleanLiteral(true), BooleanLiteral(true))) | bool",
        interpretExp("true ^^ true")
    );
    assertEqual(
        "FunctionCall(len(ArrayLiteral({0: SignedIntegerLiteral(1)}))) | uint64",
        interpretExp("{0: 1}.len()")
    );
    assertEqual(
        "FunctionCall(len(ArrayLiteral({0: SignedIntegerLiteral(1)}))) | uint64",
        interpretExp("len({0: 1})")
    );
    assertEqual(
        "FunctionCall(len(ArrayLiteral({123: FloatLiteral(1), other: FloatLiteral(-2)}))) | uint64",
        interpretExp("len({123: 1, other: -2.0})")
    );
    assertEqual(
        "FunctionCall(len(StringLiteral(\"this is a test\"))) | uint64",
        interpretExp("\"this is a test\".len()")
    );
    assertEqual(
        "FunctionCall(len(ArrayLiteral({32: TupleLiteral({StringLiteral(\"no\")}), "
            ~ "other: TupleLiteral({StringLiteral(\"yes\")})}))) | uint64",
        interpretExp("len({32: {\"no\"}, other: {\"yes\"}})")
    );
    assertEqual(
        "FunctionCall(opConcatenate(StringLiteral(\"12\"), StringLiteral(\"1\"))) | uint32[]",
        interpretExp("\"12\" ~ \"1\"")
    );
    assertEqual(
        "FunctionCall(opConcatenate(StringLiteral(\"1\"), StringLiteral(\"12\"))) | uint32[]",
        interpretExp("\"1\" ~ \"12\"")
    );
    assertEqual(
        "FunctionCall(opConcatenate(StringLiteral(\"1\"), ArrayLiteral({0: UnsignedIntegerLiteral(97)}))) | uint32[]",
        interpretExp("\"1\" ~ {0: uint32('a')}")
    );
    assertEqual(
        "FunctionCall(opConcatenate(ArrayLiteral({0: UnsignedIntegerLiteral(97)}), StringLiteral(\"1\"))) | uint32[]",
        interpretExp("{0: uint32('a')} ~ \"1\"")
    );
    assertEqual(
        "FunctionCall(opConcatenate(ArrayLiteral({other: UnsignedIntegerLiteral(0)}), StringLiteral(\"1\"))) | uint32[]",
        interpretExp("{} ~ \"1\"")
    );
    assertEqual(
        "FunctionCall(opConcatenate(ArrayLiteral({0: UnsignedIntegerLiteral(1)}), StringLiteral(\"1\"))) | uint32[]",
        interpretExp("{0: 1} ~ \"1\"")
    );
    assertEqual(
        "FunctionCall(opConcatenate(ArrayLiteral({0: UnsignedIntegerLiteral(97), 1: UnsignedIntegerLiteral(98), "
            ~ "2: UnsignedIntegerLiteral(54)}), StringLiteral(\"yes\"))) | uint32[]",
        interpretExp("{uint16('a'), 'b', 54} ~ \"yes\"")
    );
    assertEqual(
        "FunctionCall(opRange(SignedIntegerLiteral(1), SignedIntegerLiteral(2))) | {sint64 from, sint64 to}",
        interpretExp("1 .. 2")
    );
    assertEqual(
        "FunctionCall(opRange(FloatLiteral(1), FloatLiteral(2))) | {fp64 from, fp64 to}",
        interpretExp("1u .. 2")
    );
    assertEqual(
        "FunctionCall(opRange(FloatLiteral(1), FloatLiteral(2))) | {fp64 from, fp64 to}",
        interpretExp("1 .. 2u")
    );
    assertEqual(
        "FunctionCall(opRange(UnsignedIntegerLiteral(1), UnsignedIntegerLiteral(2))) | {uint64 from, uint64 to}",
        interpretExp("1u .. 2u")
    );
    assertEqual(
        "FunctionCall(opRange(FloatLiteral(-3), FloatLiteral(2.1))) | {fp64 from, fp64 to}",
        interpretExp("-3 .. 2.1")
    );
    assertEqual(
        "FunctionCall(opRange(SignedIntegerLiteral(-2), SignedIntegerLiteral(23))) | {sint32 from, sint32 to}",
        interpretExp("sint32(-2) .. sint32(23)")
    );
    assertEqual(
        "ReferenceCompare(EmptyLiteralNode({}) === EmptyLiteralNode({})) | bool",
        interpretExp("{} === {}")
    );
    assertEqual(
        "ReferenceCompare(EmptyLiteralNode({}) !== EmptyLiteralNode({})) | bool",
        interpretExp("{} !== {}")
    );
    assertEqual(
        "ReferenceCompare(EmptyLiteralNode({}) !== StringLiteral(\"2\")) | bool",
        interpretExp("{} !== \"2\"")
    );
    assertEqual(
        "ReferenceCompare(NullLiteral(null) === StringLiteral(\"2\")) | bool",
        interpretExp("null === \"2\"")
    );
    assertEqual(
        "ReferenceCompare(NullLiteral(null) === NullLiteral(null)) | bool",
        interpretExp("null === null")
    );
    assertEqual(
        "ReferenceCompare(TupleLiteral({SignedIntegerLiteral(1), SignedIntegerLiteral(2), SignedIntegerLiteral(3)}) === "
                ~ "StructLiteral({s: SignedIntegerLiteral(3), e: BooleanLiteral(true)})) | bool",
        interpretExp("{1, 2, 3} === {s: 3, e: true}")
    );
    assertEqual(
        "TypeCompare(EmptyLiteralNode({}) :: {}) | bool",
        interpretExp("{} :: {}")
    );
    assertEqual(
        "TypeCompare(StringLiteral(\"\") !: {}) | bool",
        interpretExp("\"\" !: {}")
    );
    assertEqual(
        "TypeCompare(TupleLiteral({SignedIntegerLiteral(1)}) <: {}) | bool",
        interpretExp("{1} <: {}")
    );
    assertEqual(
        "TypeCompare(StructLiteral({s: UnsignedIntegerLiteral(5)}) >: {}) | bool",
        interpretExp("{s : 5u} >: {}")
    );
    assertEqual(
        "TypeCompare(IndexAccess(TupleLiteral({EmptyLiteralNode({})})[UnsignedIntegerLiteral(0)]) <<: {}) | bool",
        interpretExp("{{}}[0] <<: {}")
    );
    assertEqual(
        "TypeCompare(MemberAccess(StructLiteral({s: EmptyLiteralNode({})}).s) <<: {}) | bool",
        interpretExp("{s: {}}.s <<: {}")
    );
    assertEqual(
        "TypeCompare(EmptyLiteralNode({}) >>: {bool b, uint32[2] test}) | bool",
        interpretExp("{} >>: {bool b, uint32[2] test}")
    );
    assertEqual(
        "TypeCompare(EmptyLiteralNode({}) <:> {{}, bool, uint32[]}) | bool",
        interpretExp("{} <:> {{}, bool, uint32[]}")
    );
    interpretExpFails("!1");
    interpretExpFails("~true");
    interpretExpFails("~1.");
    interpretExpFails("lol");
    interpretExpFails("1()");
    interpretExpFails("1.lol");
    interpretExpFails("1.lol()");
    interpretExpFails("1.opAdd()");
    interpretExpFails("1 && true");
    interpretExpFails("true && 1");
    interpretExpFails("1 || true");
    interpretExpFails("true || 1");
    interpretExpFails("1 ^^ true");
    interpretExpFails("true ^^ 1");
    interpretExpFails("1.len()");
    interpretExpFails("{}.len()");
    interpretExpFails("true.len()");
    interpretExpFails("{0: uint16(49)} ~ \"b\"");
    interpretExpFails("\"b\" ~ {0: uint16(49)}");
    interpretExpFails("\"2\" .. \"1\"");
    interpretExpFails("{} .. 0");
    interpretExpFails("sint32(-2) .. uint32(23)");
    interpretExpFails("{} === 0");
    interpretExpFails("{} !== 0");
    interpretExpFails("0 === {}");
    interpretExpFails("0 !== {}");
    interpretExpFails("null === 0");
    interpretExpFails("0 === null");
    interpretExpFails("0 === 2");
    interpretExpFails("true :: bool");
    interpretExpFails("{} :: bool");
    interpretExpFails("true :: {}");
    interpretExpFails("{0: 0, 0: 1}");
    interpretExpFails("{0: 0, 1: 1, other: 2, other: 4}");
    interpretExpFails("{s: 0, s: 1}");
}

unittest {
    interpretExpFails("1[0]");
    assertEqual(
        "IndexAccess(StringLiteral(\"1\")[UnsignedIntegerLiteral(0)]) | uint32",
        interpretExp("\"1\"[0]")
    );
    interpretExpFails("\"1\"[-1]");
    interpretExpFails("\"1\"[2]");
    assertEqual(
        "IndexAccess(StringLiteral(\"1\")[UnsignedIntegerLiteral(0)]) | uint32",
        interpretExp("\"1\"[0 + 0]")
    );
    assertEqual(
        "IndexAccess(StringLiteral(\"1\")[UnsignedIntegerLiteral(0)]) | uint32",
        interpretExp("\"1\"[0u + 0u]")
    );
    assertEqual(
        "IndexAccess(TupleLiteral({SignedIntegerLiteral(0), FloatLiteral(1)})[UnsignedIntegerLiteral(0)])"
            ~ " | sint64_lit(0)",
        interpretExp("{0, 1.}[0]")
    );
    assertEqual(
        "IndexAccess(TupleLiteral({SignedIntegerLiteral(0), FloatLiteral(1)})[UnsignedIntegerLiteral(0)])"
            ~ " | sint64_lit(0)",
        interpretExp("{0, 1.}[0 + 0]")
    );
    assertEqual(
        "IndexAccess(TupleLiteral({SignedIntegerLiteral(0), FloatLiteral(1)})[UnsignedIntegerLiteral(1)])"
            ~ " | fp64_lit(1)",
        interpretExp("{0, 1.}[1u]")
    );
    interpretExpFails("{0, 1.}[2u]");
    assertEqual(
        "IndexAccess(TupleLiteral({SignedIntegerLiteral(0), FloatLiteral(1)})[UnsignedIntegerLiteral(1)])"
            ~ " | fp64_lit(1)",
        interpretExp("{0, 1.}[0u + 1u]")
    );
    assertEqual(
        "IndexAccess(ArrayLiteral({0: SignedIntegerLiteral(1), 1: SignedIntegerLiteral(2)})["
            ~ "UnsignedIntegerLiteral(0)]) | sint64",
        interpretExp("{0: 1, 1: 2}[0u]")
    );
    assertEqual(
        "IndexAccess(ArrayLiteral({0: SignedIntegerLiteral(1), 1: SignedIntegerLiteral(2)})["
            ~ "UnsignedIntegerLiteral(1)]) | sint64",
        interpretExp("{0: 1, 1: 2}[1u]")
    );
    interpretExpFails("{0: 1, 1: 2}[2u]");
    assertEqual(
        "IndexAccess(ArrayLiteral({0: SignedIntegerLiteral(1), 1: SignedIntegerLiteral(2)})["
            ~ "UnsignedIntegerLiteral(0)]) | sint64",
        interpretExp("{0: 1, 1: 2}[0u + 0u]")
    );
    assertEqual(
        "IndexAccess(ArrayLiteral({0: FloatLiteral(1), 1: FloatLiteral(2.2)})["
            ~ "UnsignedIntegerLiteral(0)]) | fp64",
        interpretExp("{0: 1, 1: 2.2}[0u + 0u]")
    );
    interpretExpFails("{}[0]");
    interpretExpFails("{0: 1, 2: 3.0, 6: \"yesy\", other: {true}}");
}

unittest {
    interpretExpFails("{0: true, 1: 0}");
    assertEqual(
        "ArrayLiteral({0: BooleanLiteral(true), 1: BooleanLiteral(true)})"
            ~ " | bool_lit(true)[2]",
        interpretExp("{0: true, 1: true}")
    );
    assertEqual(
        "ArrayLiteral({0: BooleanLiteral(true), 1: BooleanLiteral(false)})"
            ~ " | bool[2]",
        interpretExp("{0: true, 1: false}")
    );
    assertEqual(
        "ArrayLiteral({0: FloatLiteral(1), 1: FloatLiteral(2)})"
            ~ " | fp64[2]",
        interpretExp("{0: 1, 1: 2.0}")
    );
    assertEqual(
        "ArrayLiteral({0: FloatLiteral(1), 1: FloatLiteral(1)})"
            ~ " | fp64_lit(1)[2]",
        interpretExp("{0: 1, 1: 1.0}")
    );
    assertEqual(
        "ArrayLiteral({0: SignedIntegerLiteral(1), 1: SignedIntegerLiteral(1)})"
            ~ " | sint64_lit(1)[2]",
        interpretExp("{0: 1, 1: 1}")
    );
    assertEqual(
        "ArrayLiteral({0: SignedIntegerLiteral(1), 1: SignedIntegerLiteral(2)})"
            ~ " | sint64[2]",
        interpretExp("{0: 1, 1: 2}")
    );
    assertEqual(
        "ArrayLiteral({0: SignedIntegerLiteral(1), 1: SignedIntegerLiteral(-1)})"
            ~ " | sint64[2]",
        interpretExp("{0: 1, 1: -1}")
    );
    assertEqual(
        "ArrayLiteral({1: TupleLiteral({SignedIntegerLiteral(1), SignedIntegerLiteral(2)}),"
            ~ " 0: TupleLiteral({SignedIntegerLiteral(1), SignedIntegerLiteral(2), SignedIntegerLiteral(3)})})"
            ~ " | {sint64_lit(1), sint64_lit(2)}[2]",
        interpretExp("{1: {1, 2}, 0: {1, 2, 3}}")
    );
    assertEqual(
        "ArrayLiteral({1: TupleLiteral({SignedIntegerLiteral(1), SignedIntegerLiteral(2), BooleanLiteral(true)}), "
            ~ "0: TupleLiteral({SignedIntegerLiteral(1), SignedIntegerLiteral(2), SignedIntegerLiteral(3)})})"
            ~ " | {sint64_lit(1), sint64_lit(2)}[2]",
        interpretExp("{1: {1, 2, true}, 0: {1, 2, 3}}")
    );
    assertEqual(
        "ArrayLiteral({1: TupleLiteral({SignedIntegerLiteral(1), SignedIntegerLiteral(2)}), "
            ~ "0: StructLiteral({a: SignedIntegerLiteral(1), b: SignedIntegerLiteral(2), c: SignedIntegerLiteral(3)})})"
            ~ " | {sint64_lit(1), sint64_lit(2)}[2]",
        interpretExp("{1: {1, 2}, 0: {a: 1, b: 2, c: 3}}")
    );
    assertEqual(
        "ArrayLiteral({1: TupleLiteral({SignedIntegerLiteral(1), SignedIntegerLiteral(2)}), "
            ~ "0: ArrayLiteral({0: SignedIntegerLiteral(1), 1: SignedIntegerLiteral(2), 2: SignedIntegerLiteral(3)})})"
            ~ " | {}[2]",
        interpretExp("{1: {1, 2}, 0: {0: 1, 1: 2, 2: 3}}")
    );
    assertEqual(
        "ArrayLiteral({1: TupleLiteral({SignedIntegerLiteral(1), SignedIntegerLiteral(1), SignedIntegerLiteral(2)}), "
            ~ "0: ArrayLiteral({0: SignedIntegerLiteral(1), 1: SignedIntegerLiteral(1), 2: SignedIntegerLiteral(1)})})"
            ~ " | {}[2]",
        interpretExp("{1: {1, 1, 2}, 0: {0: 1, 1: 1, 2: 1}}")
    );
    assertEqual(
        "ArrayLiteral({0: StructLiteral({a: SignedIntegerLiteral(1), b: SignedIntegerLiteral(2)}), "
            ~ "1: ArrayLiteral({0: SignedIntegerLiteral(1), 1: SignedIntegerLiteral(2)})})"
            ~ " | {}[2]",
        interpretExp("{0: {a: 1, b: 2}, 1: {0: 1, 1: 2}}")
    );
    assertEqual(
        "ArrayLiteral({0: StructLiteral({a: SignedIntegerLiteral(1), b: SignedIntegerLiteral(1), c: SignedIntegerLiteral(1)}), "
            ~ "1: StructLiteral({a: SignedIntegerLiteral(1), b: SignedIntegerLiteral(1)})})"
            ~ " | {sint64_lit(1) a, sint64_lit(1) b}[2]",
        interpretExp("{0: {a: 1, b: 1, c: 1}, 1: {a: 1, b: 1}}")
    );
    assertEqual(
        "ArrayLiteral({0: StructLiteral({a: SignedIntegerLiteral(1), b: SignedIntegerLiteral(1), c: SignedIntegerLiteral(1)}), "
            ~ "1: StructLiteral({a: SignedIntegerLiteral(1), b: SignedIntegerLiteral(1), c: SignedIntegerLiteral(1)})})"
            ~ " | {sint64_lit(1) a, sint64_lit(1) b, sint64_lit(1) c}[2]",
        interpretExp("{0: {a: 1, b: 1, c: 1}, 1: {a: 1, b: 1, c: 1}}")
    );
    assertEqual(
        "ArrayLiteral({0: StructLiteral({a: SignedIntegerLiteral(1), b: SignedIntegerLiteral(1), c: SignedIntegerLiteral(2)}), "
            ~ "1: StructLiteral({a: SignedIntegerLiteral(1), b: SignedIntegerLiteral(1), c: SignedIntegerLiteral(1)})})"
            ~ " | {sint64_lit(1) a, sint64_lit(1) b}[2]",
        interpretExp("{0: {a: 1, b: 1, c: 2}, 1: {a: 1, b: 1, c: 1}}")
    );
    assertEqual(
        "ArrayLiteral({0: StructLiteral({a: SignedIntegerLiteral(1), b: SignedIntegerLiteral(2), c: SignedIntegerLiteral(1)}), "
            ~ "1: StructLiteral({a: SignedIntegerLiteral(1), b: SignedIntegerLiteral(1), c: SignedIntegerLiteral(1)})})"
            ~ " | {sint64_lit(1) a, sint64_lit(1) c}[2]",
        interpretExp("{0: {a: 1, b: 2, c: 1}, 1: {a: 1, b: 1, c: 1}}")
    );
    assertEqual(
        "ArrayLiteral({0: StructLiteral({a: SignedIntegerLiteral(1), b: SignedIntegerLiteral(2), c: SignedIntegerLiteral(3)}), "
            ~ "1: TupleLiteral({SignedIntegerLiteral(1), SignedIntegerLiteral(2), SignedIntegerLiteral(3)})})"
            ~ " | {sint64_lit(1), sint64_lit(2), sint64_lit(3)}[2]",
        interpretExp("{0: {a: 1, b: 2, c: 3}, 1: {1, 2, 3}}")
    );
    assertEqual(
        "ArrayLiteral({0: StructLiteral({a: SignedIntegerLiteral(1), b: SignedIntegerLiteral(2), c: SignedIntegerLiteral(3)}), "
            ~ "1: TupleLiteral({SignedIntegerLiteral(1), SignedIntegerLiteral(2)})})"
            ~ " | {sint64_lit(1), sint64_lit(2)}[2]",
        interpretExp("{0: {a: 1, b: 2, c: 3}, 1: {1, 2}}")
    );
    assertEqual(
        "ArrayLiteral({0: StructLiteral({a: SignedIntegerLiteral(1), b: SignedIntegerLiteral(2), c: SignedIntegerLiteral(3)}), "
            ~ "1: TupleLiteral({SignedIntegerLiteral(1), SignedIntegerLiteral(2), SignedIntegerLiteral(3), "
            ~ "SignedIntegerLiteral(4)})})"
            ~ " | {sint64_lit(1), sint64_lit(2), sint64_lit(3)}[2]",
        interpretExp("{0: {a: 1, b: 1 + 1, c: 3}, 1: {1, 2, 3, 4}}")
    );
    assertEqual(
        "ArrayLiteral({0: EmptyLiteralNode({}), 1: TupleLiteral({BooleanLiteral(true)})})"
            ~ " | {}[2]",
        interpretExp("{0: {}, 1: {true}}")
    );
    assertEqual(
        "ArrayLiteral({0: EmptyLiteralNode({}), 1: StructLiteral({b: BooleanLiteral(true)})})"
            ~ " | {}[2]",
        interpretExp("{0: {}, 1: {b: true}}")
    );
    assertEqual(
        "ArrayLiteral({0: ArrayLiteral({0: SignedIntegerLiteral(1), 1: SignedIntegerLiteral(2)}), "
            ~ "1: TupleLiteral({SignedIntegerLiteral(1), SignedIntegerLiteral(2)})})"
            ~ " | {}[2]",
        interpretExp("{0: {0: 1, 1: 2}, 1: {1, 2}}")
    );
    assertEqual(
        "ArrayLiteral({0: ArrayLiteral({0: SignedIntegerLiteral(1), 1: SignedIntegerLiteral(1)}), "
            ~ "1: TupleLiteral({SignedIntegerLiteral(1), SignedIntegerLiteral(1)})})"
            ~ " | {}[2]",
        interpretExp("{0: {0: 1, 1: 1}, 1: {1, 1}}")
    );
    assertEqual(
        "ArrayLiteral({0: StringLiteral(\"hello\"), 1: StringLiteral(\"hello\")})"
            ~ " | str32_lit(\"hello\")[2]",
        interpretExp("{0: \"hello\", 1: \"hello\"}")
    );
    assertEqual(
        "ArrayLiteral({0: StringLiteral(\"hello\"), 1: StringLiteral(\"hell\")})"
            ~ " | str32_lit(\"hell\")[2]",
        interpretExp("{0: \"hello\", 1: \"hell\"}")
    );
    assertEqual(
        "ArrayLiteral({0: StringLiteral(\"hello\"), 1: StringLiteral(\"allo\")})"
            ~ " | uint32[4][2]",
        interpretExp("{0: \"hello\", 1: \"allo\"}")
    );
    assertEqual(
        "ArrayLiteral({0: StringLiteral(\"allo\"), 1: StringLiteral(\"hello\")})"
            ~ " | uint32[4][2]",
        interpretExp("{0: \"allo\", 1: \"hello\"}")
    );
    assertEqual(
        "ArrayLiteral({0: StringLiteral(\"hello\"), 1: TupleLiteral({SignedIntegerLiteral(1), SignedIntegerLiteral(1)})})"
            ~ " | {}[2]",
        interpretExp("{0: \"hello\", 1: {1, 1}}")
    );
}

unittest {
    assertEqual(
        "Conditional(BooleanLiteral(true), FloatLiteral(1), FloatLiteral(1)) | fp64_lit(1)",
        interpretExp("1 if true else 1.0")
    );
    assertEqual(
        "Conditional(BooleanLiteral(true), FloatLiteral(1), FloatLiteral(-1)) | fp64",
        interpretExp("1 if true else -1.0")
    );
    assertEqual(
        "Conditional(BooleanLiteral(false), FloatLiteral(2), FloatLiteral(2)) | fp64",
        interpretExp("2 if false else 2u")
    );
    assertEqual(
        "Conditional(BooleanLiteral(false), FloatLiteral(-2), FloatLiteral(2)) | fp64",
        interpretExp("-2 if false else 2u")
    );
    assertEqual(
        "Conditional(BooleanLiteral(false), StringLiteral(\"hello\"), StringLiteral(\"hell\")) | str32_lit(\"hell\")",
        interpretExp("\"hello\" if false else \"hell\"")
    );
    assertEqual(
        "Conditional(BooleanLiteral(false), StringLiteral(\"allo\"), StringLiteral(\"hello\")) | uint32[4]",
        interpretExp("\"allo\" if false else \"hello\"")
    );
    assertEqual(
        "Conditional(BooleanLiteral(false), "
            ~ "TupleLiteral({SignedIntegerLiteral(1), SignedIntegerLiteral(2), BooleanLiteral(true)}), "
            ~ "TupleLiteral({SignedIntegerLiteral(1), SignedIntegerLiteral(2), SignedIntegerLiteral(3)})) "
            ~ "| {sint64_lit(1), sint64_lit(2)}",
        interpretExp("{1, 2, true} if false else {1, 2, 3}")
    );
    interpretExpFails("false if true else 2");
    interpretExpFails("{} if true else 2");
    interpretExpFails("2 if \"lol\" else 2");
}

unittest {
    auto context = new Context();
    assertEqual(
        "TypeDefinition(def test: bool)",
        interpretStmt("def test: bool", context)
    );
    assertEqual(
        "TypeDefinition(def wow: {uint32[1], {bool b}, fp32})",
        interpretStmt("def wow: {uint32[1], {test b}, fp32}", context)
    );
    interpretStmtFails("def test: uint32", context);
    assertEqual(
        "TypeCompare(EmptyLiteralNode({}) >>: {bool}) | bool",
        interpretExp("{} >>: {test}", context)
    );
}

unittest {
    auto context = new Context();
    assertEqual(
        "TypeDefinition(def tup1: {uint16})",
        interpretStmt("def tup1: {uint16}", context)
    );
    assertEqual(
        "TupleLiteral({UnsignedIntegerLiteral(0)}) | {uint16_lit(0)}",
        interpretExp("tup1{}", context)
    );
    assertEqual(
        "TupleLiteral({UnsignedIntegerLiteral(4)}) | {uint16_lit(4)}",
        interpretExp("tup1{4}", context)
    );
    interpretExpFails("tup1{s: 4}", context);
    interpretExpFails("tup1{0: 4}", context);
    interpretExpFails("tup1{4, 4}", context);
    assertEqual(
        "TypeDefinition(def strc1: {uint16 s})",
        interpretStmt("def strc1: {uint16 s}", context)
    );
    assertEqual(
        "StructLiteral({s: UnsignedIntegerLiteral(0)}) | {uint16_lit(0) s}",
        interpretExp("strc1{}", context)
    );
    assertEqual(
        "StructLiteral({s: UnsignedIntegerLiteral(4)}) | {uint16_lit(4) s}",
        interpretExp("strc1{4}", context)
    );
    assertEqual(
        "StructLiteral({s: UnsignedIntegerLiteral(4)}) | {uint16_lit(4) s}",
        interpretExp("strc1{s: 4}", context)
    );
    interpretExpFails("strc1{0: 4}", context);
    interpretExpFails("strc1{4, 4}", context);
    interpretExpFails("strc1{s: 4, t: 4}", context);
    assertEqual(
        "TypeDefinition(def strc2: {uint16 s, fp32 t})",
        interpretStmt("def strc2: {uint16 s, fp32 t}", context)
    );
    assertEqual(
        "StructLiteral({s: UnsignedIntegerLiteral(0), t: FloatLiteral(0)}) | {uint16_lit(0) s, fp32_lit(0) t}",
        interpretExp("strc2{}", context)
    );
    assertEqual(
        "StructLiteral({s: UnsignedIntegerLiteral(4), t: FloatLiteral(0)}) | {uint16_lit(4) s, fp32_lit(0) t}",
        interpretExp("strc2{4}", context)
    );
    assertEqual(
        "StructLiteral({s: UnsignedIntegerLiteral(4), t: FloatLiteral(0)}) | {uint16_lit(4) s, fp32_lit(0) t}",
        interpretExp("strc2{s: 4}", context)
    );
    assertEqual(
        "StructLiteral({s: UnsignedIntegerLiteral(4), t: FloatLiteral(2.3)}) | {uint16_lit(4) s, fp32_lit(2.3) t}",
        interpretExp("strc2{4, 2.3}", context)
    );
    assertEqual(
        "StructLiteral({s: UnsignedIntegerLiteral(4), t: FloatLiteral(2.3)}) | {uint16_lit(4) s, fp32_lit(2.3) t}",
        interpretExp("strc2{s: 4, t: 2.3}", context)
    );
    assertEqual(
        "TypeDefinition(def tup2: {{bool}})",
        interpretStmt("def tup2: {{bool}}", context)
    );
    assertEqual(
        "TupleLiteral({NullLiteral(null)}) | {null}",
        interpretExp("tup2{}", context)
    );
    assertEqual(
        "TypeDefinition(def arr1: uint32[][])",
        interpretStmt("def arr1: uint32[][]", context)
    );
    assertEqual(
        "ArrayLiteral({other: NullLiteral(null)}) | null[0]",
        interpretExp("arr1{}", context)
    );
    assertEqual(
        "ArrayLiteral({0: ArrayLiteral({other: UnsignedIntegerLiteral(0)}), "
            ~ "1: ArrayLiteral({other: UnsignedIntegerLiteral(0)})}) | uint32_lit(0)[0][2]",
        interpretExp("arr1{{}, {}}", context)
    );
    assertEqual(
        "TypeDefinition(def arr2: fp32[2][3])",
        interpretStmt("def arr2: fp32[2][3]", context)
    );
    assertEqual(
        "ArrayLiteral({2: ArrayLiteral({1: FloatLiteral(0), other: FloatLiteral(0)}), "
            ~ "other: ArrayLiteral({1: FloatLiteral(0), other: FloatLiteral(0)})}) | fp32_lit(0)[2][3]",
        interpretExp("arr2{}", context)
    );
    assertEqual(
        "TypeDefinition(def arr3: fp32[][3])",
        interpretStmt("def arr3: fp32[][3]", context)
    );
    assertEqual(
        "ArrayLiteral({2: NullLiteral(null), other: NullLiteral(null)}) | null[3]",
        interpretExp("arr3{}", context)
    );
    interpretExpFails("arr3{3: {}}", context);
    assertEqual(
        "ArrayLiteral({1: ArrayLiteral({other: FloatLiteral(0)}), 2: NullLiteral(null), other: NullLiteral(null)})"
            ~ " | fp32_lit(0)[0][3]",
        interpretExp("arr3{1: {}}", context)
    );
    assertEqual(
        "ArrayLiteral({2: ArrayLiteral({other: FloatLiteral(0)}), other: ArrayLiteral({other: FloatLiteral(0)})})"
            ~ " | fp32_lit(0)[0][3]",
        interpretExp("arr3{2: {}, other: {}}", context)
    );
    assertEqual(
        "TypeDefinition(def arr4: fp32[3][])",
        interpretStmt("def arr4: fp32[3][]", context)
    );
    assertEqual(
        "ArrayLiteral({other: ArrayLiteral({2: FloatLiteral(0), other: FloatLiteral(0)})}) | fp32_lit(0)[3][0]",
        interpretExp("arr4{}", context)
    );
    assertEqual(
        "ArrayLiteral({0: ArrayLiteral({2: FloatLiteral(0), other: FloatLiteral(0)})}) | fp32_lit(0)[3][1]",
        interpretExp("arr4{{}}", context)
    );
    assertEqual(
        "TypeDefinition(def any: {})",
        interpretStmt("def any: {}", context)
    );
    assertEqual(
        "ArrayLiteral({other: ArrayLiteral({other: NullLiteral(null)})}) | null[0][0]",
        interpretExp("any[0][0]{}", context)
    );
}

unittest {
    auto context = new Context();
    assertEqual(
        "VariableDeclaration(bool a = BooleanLiteral(true))",
        interpretStmt("let a = true", context)
    );
    interpretStmtFails("let a = 1", context);
    assertEqual(
        "VariableDeclaration(sint64 b = SignedIntegerLiteral(2))",
        interpretStmt("var b = 1 + 1", context)
    );
    assertEqual(
        "VariableDeclaration(uint32[2] array = ArrayLiteral({1: UnsignedIntegerLiteral(0), other: UnsignedIntegerLiteral(0)}))",
        interpretStmt("var uint32[2] array = {}", context)
    );
    interpretStmtFails("var bool b = 1 + 1", context);
    interpretStmtFails("let uint8 c", context);
    assertEqual(
        "VariableDeclaration(fp32 f = FloatLiteral(0))",
        interpretStmt("var fp32 f", context)
    );
}

unittest {
    auto context = new Context();
    assertEqual(
        "VariableDeclaration(bool a = BooleanLiteral(true))",
        interpretStmt("var a = true", context)
    );
    assertEqual(
        "Assignment(FieldAccess(a) = BooleanLiteral(false))",
        interpretStmt("a = false", context)
    );
    interpretStmtFails("a = 2", context);
    assertEqual(
        "TypeDefinition(def Vec2d: {fp64 x, fp64 y})",
        interpretStmt("def Vec2d: {fp64 x, fp64 y}", context)
    );
    assertEqual(
        "VariableDeclaration({fp64 x, fp64 y} b = StructLiteral({x: FloatLiteral(-1), y: FloatLiteral(3.6)}))",
        interpretStmt("let Vec2d b = {-1, 3.6}", context)
    );
    assertEqual(
        "Assignment(MemberAccess(FieldAccess(b).x) = FunctionCall(opDivide(MemberAccess(FieldAccess(b).x), FloatLiteral(-2))))",
        interpretStmt("b.x /= -2", context)
    );
    interpretStmtFails("b.y = \"lol\"", context);
    assertEqual(
        "VariableDeclaration(sint32[2] c = ArrayLiteral({1: SignedIntegerLiteral(0), other: SignedIntegerLiteral(0)}))",
        interpretStmt("var sint32[2] c", context)
    );
    assertEqual(
        "Assignment(IndexAccess(FieldAccess(c)[UnsignedIntegerLiteral(1)]) = SignedIntegerLiteral(2))",
        interpretStmt("c[1] = 2", context)
    );
    interpretStmtFails("c[0] = \"no\"", context);
    assertEqual(
        "VariableDeclaration(bool d = BooleanLiteral(true))",
        interpretStmt("let d = true", context)
    );
    interpretStmtFails("d = false", context);
}

unittest {
    auto context = new Context();
    assertEqual(
        "VariableDeclaration(uint32[3] s32 = StringLiteral(\"hey\"))",
        interpretStmt("let s32 = \"hey\"", context)
    );
    assertEqual(
        "VariableDeclaration(uint16[] s16 = StringLiteral(\"hey\"))",
        interpretStmt("let uint16[] s16 = \"hey\"", context)
    );
    assertEqual(
        "VariableDeclaration(uint8[] s8 = StringLiteral(\"hey\"))",
        interpretStmt("let uint8[] s8 = \"hey\"", context)
    );
}

unittest {
    /*
        def Any: {}
        Any[+1u]{}
        Any[+1u][+1u]{}
        Any[1][+1u]{}
        Any[+1u][1]{}
        Any[][+1u]{}
        Any[+1u][]{}
    */
}

private string interpretExp(alias info = getAllInfo)(string source, Context context = new Context()) {
    auto tokenizer = new Tokenizer(new DCharReader(source));
    if (tokenizer.head().getKind() == Kind.INDENTATION) {
        tokenizer.advance();
    }
    return info(tokenizer.parseExpression().expandOperators().interpret(context));
}

private void interpretExpFails(string source, Context context = new Context()) {
    try {
        auto node = source.interpretExp(context);
        throw new AssertionError("Expected a source exception, but got node:\n" ~ node);
    } catch (SourceException exception) {
        debug (verboseTests) {
            import std.stdio : stderr;
            stderr.writeln(exception.getErrorInformation(source).toString());
        }
    }
}

private string interpretStmt(string source, Context context = new Context()) {
    auto tokenizer = new Tokenizer(new DCharReader(source));
    string[] results;
    foreach (statement; tokenizer.parseStatements()) {
        results ~= statement.expandOperators().interpret(context).getTreeInfo();
    }
    return results.join!"\n"();
}

private void interpretStmtFails(string source, Context context = new Context()) {
    try {
        auto node = source.interpretStmt(context);
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
