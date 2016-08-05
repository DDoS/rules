module ruleslang.test.syntax.tokenizer;

import std.conv : to;
import std.format : format;

import ruleslang.syntax.source;
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
    assertLexNoIndent("0b0", "SignedIntegerLiteral(0b0)");
    assertLexNoIndent("0b11", "SignedIntegerLiteral(0b11)");
    assertLexNoIndent("0B110101", "SignedIntegerLiteral(0B110101)");
    assertLexNoIndent("0b1101_0001", "SignedIntegerLiteral(0b1101_0001)");
    assertLexNoIndent("0b1101__0001", "SignedIntegerLiteral(0b1101__0001)");
    assertLexNoIndent("0b1101_0100_0001", "SignedIntegerLiteral(0b1101_0100_0001)");
    assertLexNoIndent("0b1101_0100____0001", "SignedIntegerLiteral(0b1101_0100____0001)");
    assertLexNoIndent("0b0u", "UnsignedIntegerLiteral(0b0)");
    assertLexNoIndent("0b0U", "UnsignedIntegerLiteral(0b0)");

    assertLexNoIndent("0", "SignedIntegerLiteral(0)");
    assertLexNoIndent("012", "SignedIntegerLiteral(012)");
    assertLexNoIndent("564", "SignedIntegerLiteral(564)");
    assertLexNoIndent("5_000", "SignedIntegerLiteral(5_000)");
    assertLexNoIndent("5__000", "SignedIntegerLiteral(5__000)");
    assertLexNoIndent("5_000_000", "SignedIntegerLiteral(5_000_000)");
    assertLexNoIndent("5_000____000", "SignedIntegerLiteral(5_000____000)");
    assertLexNoIndent("564u", "UnsignedIntegerLiteral(564)");
    assertLexNoIndent("564U", "UnsignedIntegerLiteral(564)");

    assertLexNoIndent("0x0", "SignedIntegerLiteral(0x0)");
    assertLexNoIndent("0xAf", "SignedIntegerLiteral(0xAf)");
    assertLexNoIndent("0XA24E4", "SignedIntegerLiteral(0XA24E4)");
    assertLexNoIndent("0xDEAD_BEEF", "SignedIntegerLiteral(0xDEAD_BEEF)");
    assertLexNoIndent("0x2192__CAFE", "SignedIntegerLiteral(0x2192__CAFE)");
    assertLexNoIndent("0xBABE_291c_13b2", "SignedIntegerLiteral(0xBABE_291c_13b2)");
    assertLexNoIndent("0x4235_1232____54fd3", "SignedIntegerLiteral(0x4235_1232____54fd3)");
    assertLexNoIndent("0xAfu", "UnsignedIntegerLiteral(0xAf)");
    assertLexNoIndent("0xAfU", "UnsignedIntegerLiteral(0xAf)");
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
        "let n = 12u; var fact = 1\n" ~
        "for var i = 2; i <= n; i += 1\n" ~
        "    fact *= i\n" ~
        "printfln(\"%d! is %d\", n, fact)\n" ~
        "## Random block comment ##",
        "Indentation()",
        "Indentation()", "Keyword(let)", "Identifier(n)", "Symbol(=)", "UnsignedIntegerLiteral(12)", "Terminator(;)",
        "Keyword(var)", "Identifier(fact)", "Symbol(=)", "SignedIntegerLiteral(1)",
        "Indentation()", "Keyword(for)", "Keyword(var)", "Identifier(i)", "Symbol(=)", "SignedIntegerLiteral(2)", "Terminator(;)",
        "Identifier(i)", "Symbol(<=)", "Identifier(n)", "Terminator(;)",
        "Identifier(i)", "Symbol(+=)", "SignedIntegerLiteral(1)",
        "Indentation(    )", "Identifier(fact)", "Symbol(*=)", "Identifier(i)",
        "Indentation()", "Identifier(printfln)", "Symbol(()", "StringLiteral(\"%d! is %d\")", "Symbol(,)",
        "Identifier(n)", "Symbol(,)", "Identifier(fact)", "Symbol())",
        "Indentation()"
    );
}

private void assertLexNoIndent(string source, string[] expected ...) {
    auto tokenizer = new Tokenizer(new DCharReader(source));
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
    auto tokenizer = new Tokenizer(new DCharReader(source));
    string[] tokens = [];
    while (tokenizer.has()) {
        tokens ~= tokenizer.head().toString();
        tokenizer.advance();
    }
    assertEqual(expected, tokens);
}
