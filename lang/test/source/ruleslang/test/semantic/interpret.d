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
}

private string interpret(string source) {
    auto tokenizer = new Tokenizer(new DCharReader(source));
    if (tokenizer.head().getKind() == Kind.INDENTATION) {
        tokenizer.advance();
    }
    auto node = tokenizer
            .parseExpression()
            .expandOperators()
            .interpret(new Context());
    string str = node.toString();
    auto typedNode = cast(immutable TypedNode) node;
    if (typedNode !is null) {
        str = str ~ " | " ~ typedNode.getType().toString();
    }
    return str;
}
