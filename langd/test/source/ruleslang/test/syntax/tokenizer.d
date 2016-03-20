module ruleslang.test.syntax.tokenizer;

import std.conv;
import std.format;

import ruleslang.syntax.dcharstream;
import ruleslang.syntax.token;
import ruleslang.syntax.tokenizer;

import ruleslang.test.assertion;

unittest {
    assertLexNoIndent("t", "Identifier(t)");
    assertLexNoIndent("t12", "Identifier(t12)");
    assertLexNoIndent("_", "Identifier(_)");
    assertLexNoIndent("_12", "Identifier(_12)");
    assertLexNoIndent("test", "Identifier(test)");
}

unittest {
    assertLex("    test", "Indentation(    )", "Identifier(test)");
    assertLex("\ntest", "Indentation()", "Indentation()", "Identifier(test)");
    assertLex("\r\ntest", "Indentation()", "Indentation()", "Identifier(test)");
    assertLex("\r    test", "Indentation()", "Indentation(    )", "Identifier(test)");
    assertLex("\r\ttest", "Indentation()", "Indentation(\t)", "Identifier(test)");
    assertLex("test\nyou", "Indentation()", "Identifier(test)", "Indentation()", "Identifier(you)");
    assertLex("hello\n you", "Indentation()", "Identifier(hello)", "Indentation( )", "Identifier(you)");
    assertLex(" hello\n you", "Indentation( )", "Identifier(hello)", "Indentation( )", "Identifier(you)");
    assertLex(" \\\ntest", "Indentation( )", "Identifier(test)");
}

unittest {
    assertLex("test;that", "Indentation()", "Identifier(test)", "Terminator(;)", "Identifier(that)");
}

unittest {
    foreach (keyword; KEYWORDS) {
        auto stringKeyword = keyword.to!string;
        assertLexNoIndent(stringKeyword, format("Keyword(%s)", stringKeyword));
    }
}

unittest {
    foreach (symbol; SYMBOLS) {
        auto stringSymbol = symbol.to!string;
        assertLexNoIndent(stringSymbol, format("Symbol(%s)", stringSymbol));
    }
}

unittest {
    assertLexNoIndent("false", "BooleanLiteral(false)");
    assertLexNoIndent("true", "BooleanLiteral(true)");
}

unittest {
    assertLexNoIndent("\"test\"", "StringLiteral(\"test\")");
    assertLexNoIndent("\"  \"", "StringLiteral(\"  \")");
    assertLexNoIndent("\"  t  \"", "StringLiteral(\"  t  \")");
    assertLexNoIndent("\"te\\nst\"", "StringLiteral(\"te\\nst\")");
    assertLexNoIndent("\"te\\\"nst\"", "StringLiteral(\"te\\\"nst\")");
    assertLexNoIndent("\"te\\\\st\"", "StringLiteral(\"te\\\\st\")");
    assertLexNoIndent("\"te\\\\nst\"", "StringLiteral(\"te\\\\nst\")");
    assertLexNoIndent("\"\\u00000000\"", "StringLiteral(\"\\u00000000\")");
    assertLexNoIndent("\"\\u0\"", "StringLiteral(\"\\u0\")");
    assertLexNoIndent("\"\\u214ade\"", "StringLiteral(\"\\u214ade\")");
    assertLexNoIndent("\"\\u214ader\"", "StringLiteral(\"\\u214ader\")");
}

unittest {
    assertLexNoIndent("0b0", "IntegerLiteral(0b0)");
    assertLexNoIndent("0b11", "IntegerLiteral(0b11)");
    assertLexNoIndent("0B110101", "IntegerLiteral(0B110101)");
    assertLexNoIndent("0b1101_0001", "IntegerLiteral(0b1101_0001)");
    assertLexNoIndent("0b1101__0001", "IntegerLiteral(0b1101__0001)");
    assertLexNoIndent("0b1101_0100_0001", "IntegerLiteral(0b1101_0100_0001)");
    assertLexNoIndent("0b1101_0100____0001", "IntegerLiteral(0b1101_0100____0001)");

    assertLexNoIndent("0", "IntegerLiteral(0)");
    assertLexNoIndent("012", "IntegerLiteral(012)");
    assertLexNoIndent("564", "IntegerLiteral(564)");
    assertLexNoIndent("5_000", "IntegerLiteral(5_000)");
    assertLexNoIndent("5__000", "IntegerLiteral(5__000)");
    assertLexNoIndent("5_000_000", "IntegerLiteral(5_000_000)");
    assertLexNoIndent("5_000____000", "IntegerLiteral(5_000____000)");

    assertLexNoIndent("0x0", "IntegerLiteral(0x0)");
    assertLexNoIndent("0xAf", "IntegerLiteral(0xAf)");
    assertLexNoIndent("0XA24E4", "IntegerLiteral(0XA24E4)");
    assertLexNoIndent("0xDEAD_BEEF", "IntegerLiteral(0xDEAD_BEEF)");
    assertLexNoIndent("0x2192__CAFE", "IntegerLiteral(0x2192__CAFE)");
    assertLexNoIndent("0xBABE_291c_13b2", "IntegerLiteral(0xBABE_291c_13b2)");
    assertLexNoIndent("0x4235_1232____54fd3", "IntegerLiteral(0x4235_1232____54fd3)");
}

unittest {
    assertLexNoIndent("1.", "FloatLiteral(1.)");
    assertLexNoIndent("12_345_689.", "FloatLiteral(12_345_689.)");
    assertLexNoIndent("0.1", "FloatLiteral(0.1)");
    assertLexNoIndent("1.0", "FloatLiteral(1.0)");
    assertLexNoIndent(".1", "FloatLiteral(.1)");
    assertLexNoIndent(".14321", "FloatLiteral(.14321)");
    assertLexNoIndent("1e2", "FloatLiteral(1e2)");
    assertLexNoIndent("1.e2", "FloatLiteral(1.e2)");
    assertLexNoIndent("1.0e2", "FloatLiteral(1.0e2)");
    assertLexNoIndent("113.211e21", "FloatLiteral(113.211e21)");
    assertLexNoIndent(".1e2", "FloatLiteral(.1e2)");
    assertLexNoIndent("1e-2", "FloatLiteral(1e-2)");
    assertLexNoIndent("1.e+2", "FloatLiteral(1.e+2)");
    assertLexNoIndent("1.0e-2", "FloatLiteral(1.0e-2)");
    assertLexNoIndent(".1e+2", "FloatLiteral(.1e+2)");
    assertLexNoIndent("1_113.291_121e9", "FloatLiteral(1_113.291_121e9)");
}

unittest {
    assertLex("test\\\nyou", "Indentation()", "Identifier(test)", "Identifier(you)");
    assertLex("#A \tcomment!\ntest", "Indentation()", "Indentation()", "Identifier(test)");
    assertLex("#Testing #some characters in \\comments\ntest", "Indentation()", "Indentation()", "Identifier(test)");
    assertLex("## Comment\\test ## test", "Indentation()", "Identifier(test)");
    assertLex("## Two ## #Comments\n test", "Indentation()", "Indentation( )", "Identifier(test)");
    assertLex("## Hello \n World \r\t\n ##test", "Indentation()", "Identifier(test)");
    assertLex("### You\nCan ## Nest\nComments # like this ## ###test", "Indentation()", "Identifier(test)");
}

unittest {
    // Not necessarily representative of the actual language, just to test the lexer
    assertLex(
        "# Computes and prints the factorial of n\n" ~
        "let n = 12; var fact = 1\n" ~
        "for var i = 2; i <= n; i += 1\n" ~
        "    fact *= i\n" ~
        "printfln(\"%d! is %d\", n, fact)\n" ~
        "## Random block comment ##",
        "Indentation()",
        "Indentation()", "Keyword(let)", "Identifier(n)", "Symbol(=)", "IntegerLiteral(12)", "Terminator(;)",
        "Keyword(var)", "Identifier(fact)", "Symbol(=)", "IntegerLiteral(1)",
        "Indentation()", "Keyword(for)", "Keyword(var)", "Identifier(i)", "Symbol(=)", "IntegerLiteral(2)", "Terminator(;)",
        "Identifier(i)", "Symbol(<=)", "Identifier(n)", "Terminator(;)",
        "Identifier(i)", "Symbol(+=)", "IntegerLiteral(1)",
        "Indentation(    )", "Identifier(fact)", "Symbol(*=)", "Identifier(i)",
        "Indentation()", "Identifier(printfln)", "Symbol(()", "StringLiteral(\"%d! is %d\")", "Symbol(,)",
        "Identifier(n)", "Symbol(,)", "Identifier(fact)", "Symbol())",
        "Indentation()"
    );
}

private void assertLexNoIndent(string source, string[] expected ...) {
    auto tokenizer = new Tokenizer(new DCharReader(new StringDCharStream(source)));
    string[] tokens = [];
    if (tokenizer.head().getKind() == Kind.INDENTATION) {
        tokenizer.advance();
    }
    while (tokenizer.has()) {
        tokens ~= tokenizer.head().toString();
        tokenizer.advance();
    }
    assertEqual(expected, tokens);
}

private void assertLex(string source, string[] expected ...) {
    auto tokenizer = new Tokenizer(new DCharReader(new StringDCharStream(source)));
    string[] tokens = [];
    while (tokenizer.has()) {
        tokens ~= tokenizer.head().toString();
        tokenizer.advance();
    }
    assertEqual(expected, tokens);
}
