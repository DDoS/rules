package syntax_test

import (
    "fmt"
    "testing"
    "github.com/stretchr/testify/assert"
    "github.com/michael-golfi/rules/lang/syntax"
)

func TestLexIdentifier(t *testing.T) {
    assertLexNoIndent(t, "t", "Identifier(t)")
    assertLexNoIndent(t, "t12", "Identifier(t12)")
    assertLexNoIndent(t, "_", "Identifier(_)")
    assertLexNoIndent(t, "_12", "Identifier(_12)")
    assertLexNoIndent(t, "test", "Identifier(test)")
}

func TestLexIndentation(t *testing.T) {
    assertLex(t, "    test", "Indentation(    )", "Identifier(test)")
    assertLex(t, "\ntest", "Indentation()", "Indentation()", "Identifier(test)")
    assertLex(t, "\r\ntest", "Indentation()", "Indentation()", "Identifier(test)")
    assertLex(t, "\r    test", "Indentation()", "Indentation(    )", "Identifier(test)")
    assertLex(t, "\r\ttest", "Indentation()", "Indentation(\t)", "Identifier(test)")
    assertLex(t, "test\nyou", "Indentation()", "Identifier(test)", "Indentation()", "Identifier(you)")
    assertLex(t, "hello\n you", "Indentation()", "Identifier(hello)", "Indentation( )", "Identifier(you)")
    assertLex(t, " hello\n you", "Indentation( )", "Identifier(hello)", "Indentation( )", "Identifier(you)")
    assertLex(t, " \\\ntest", "Indentation( )", "Identifier(test)")
}

func TestLexTerminator(t *testing.T) {
    assertLex(t, "test;that", "Indentation()", "Identifier(test)", "Terminator(;)", "Identifier(that)")
}

func TestLexKeyword(t *testing.T) {
    for _, keyword := range syntax.KEYWORDS {
        stringKeword := string(keyword)
        assertLexNoIndent(t, stringKeword, fmt.Sprintf("Keyword(%s)", stringKeword))
    }
}

func TestLexSymbol(t *testing.T) {
    for _, symbol := range syntax.SYMBOLS {
        stringSymbol := string(symbol)
        assertLexNoIndent(t, stringSymbol, fmt.Sprintf("Symbol(%s)", stringSymbol))
    }
}

func TestLexBooleanLiteral(t *testing.T) {
    assertLexNoIndent(t, "false", "BooleanLiteral(false)")
    assertLexNoIndent(t, "true", "BooleanLiteral(true)")
}

func TestLextStringLiteral(t *testing.T) {
    assertLexNoIndent(t, "\"test\"", "StringLiteral(\"test\")")
    assertLexNoIndent(t, "\"  \"", "StringLiteral(\"  \")")
    assertLexNoIndent(t, "\"  t  \"", "StringLiteral(\"  t  \")")
    assertLexNoIndent(t, "\"te\\nst\"", "StringLiteral(\"te\\nst\")")
    assertLexNoIndent(t, "\"te\\\"nst\"", "StringLiteral(\"te\\\"nst\")")
    assertLexNoIndent(t, "\"te\\\\st\"", "StringLiteral(\"te\\\\st\")")
    assertLexNoIndent(t, "\"te\\\\nst\"", "StringLiteral(\"te\\\\nst\")")
    assertLexNoIndent(t, "\"\\u00000000\"", "StringLiteral(\"\\u00000000\")")
    assertLexNoIndent(t, "\"\\u0\"", "StringLiteral(\"\\u0\")")
    assertLexNoIndent(t, "\"\\u214ade\"", "StringLiteral(\"\\u214ade\")")
    assertLexNoIndent(t, "\"\\u214ader\"", "StringLiteral(\"\\u214ader\")")
}

func TestLexBinaryIntegerLiteral(t *testing.T) {
    assertLexNoIndent(t, "0b0", "BinaryIntegerLiteral(0b0)")
    assertLexNoIndent(t, "0b11", "BinaryIntegerLiteral(0b11)")
    assertLexNoIndent(t, "0B110101", "BinaryIntegerLiteral(0B110101)")
    assertLexNoIndent(t, "0b1101_0001", "BinaryIntegerLiteral(0b1101_0001)")
    assertLexNoIndent(t, "0b1101__0001", "BinaryIntegerLiteral(0b1101__0001)")
    assertLexNoIndent(t, "0b1101_0100_0001", "BinaryIntegerLiteral(0b1101_0100_0001)")
    assertLexNoIndent(t, "0b1101_0100____0001", "BinaryIntegerLiteral(0b1101_0100____0001)")
}

func TestLexDecimalIntegerLiteral(t *testing.T) {
    assertLexNoIndent(t, "0", "DecimalIntegerLiteral(0)")
    assertLexNoIndent(t, "012", "DecimalIntegerLiteral(012)")
    assertLexNoIndent(t, "564", "DecimalIntegerLiteral(564)")
    assertLexNoIndent(t, "5_000", "DecimalIntegerLiteral(5_000)")
    assertLexNoIndent(t, "5__000", "DecimalIntegerLiteral(5__000)")
    assertLexNoIndent(t, "5_000_000", "DecimalIntegerLiteral(5_000_000)")
    assertLexNoIndent(t, "5_000____000", "DecimalIntegerLiteral(5_000____000)")
}

func TestLexHexadecimalIntegerLiteral(t *testing.T) {
    assertLexNoIndent(t, "0x0", "HexadecimalIntegerLiteral(0x0)")
    assertLexNoIndent(t, "0xAf", "HexadecimalIntegerLiteral(0xAf)")
    assertLexNoIndent(t, "0XA24E4", "HexadecimalIntegerLiteral(0XA24E4)")
    assertLexNoIndent(t, "0xDEAD_BEEF", "HexadecimalIntegerLiteral(0xDEAD_BEEF)")
    assertLexNoIndent(t, "0x2192__CAFE", "HexadecimalIntegerLiteral(0x2192__CAFE)")
    assertLexNoIndent(t, "0xBABE_291c_13b2", "HexadecimalIntegerLiteral(0xBABE_291c_13b2)")
    assertLexNoIndent(t, "0x4235_1232____54fd3", "HexadecimalIntegerLiteral(0x4235_1232____54fd3)")
}

func TestLexFloatLiteral(t *testing.T) {
    assertLexNoIndent(t, "1.", "FloatLiteral(1.)");
    assertLexNoIndent(t, "12_345_689.", "FloatLiteral(12_345_689.)");
    assertLexNoIndent(t, "1.0", "FloatLiteral(1.0)");
    assertLexNoIndent(t, ".1", "FloatLiteral(.1)");
    assertLexNoIndent(t, ".14321", "FloatLiteral(.14321)");
    assertLexNoIndent(t, "1e2", "FloatLiteral(1e2)");
    assertLexNoIndent(t, "1.e2", "FloatLiteral(1.e2)");
    assertLexNoIndent(t, "1.0e2", "FloatLiteral(1.0e2)");
    assertLexNoIndent(t, "113.211e21", "FloatLiteral(113.211e21)");
    assertLexNoIndent(t, ".1e2", "FloatLiteral(.1e2)");
    assertLexNoIndent(t, "1e-2", "FloatLiteral(1e-2)");
    assertLexNoIndent(t, "1.e+2", "FloatLiteral(1.e+2)");
    assertLexNoIndent(t, "1.0e-2", "FloatLiteral(1.0e-2)");
    assertLexNoIndent(t, ".1e+2", "FloatLiteral(.1e+2)");
    assertLexNoIndent(t, "1_113.291_121e9", "FloatLiteral(1_113.291_121e9)");
}

func TestLexIgnored(t *testing.T) {
    assertLex(t, "test\\\nyou", "Indentation()", "Identifier(test)", "Identifier(you)")
    assertLex(t, "#A \tcomment!\ntest", "Indentation()", "Indentation()", "Identifier(test)")
    assertLex(t, "#Testing #some characters in \\comments\ntest", "Indentation()", "Indentation()", "Identifier(test)")
    assertLex(t, "## Comment\\test ## test", "Indentation()", "Identifier(test)")
    assertLex(t, "## Two ## #Comments\n test", "Indentation()", "Indentation( )", "Identifier(test)")
    assertLex(t, "## Hello \n World \r\t\n ##test", "Indentation()", "Identifier(test)")
    assertLex(t, "### You\nCan ## Nest\nComments # like this ## ###test", "Indentation()", "Identifier(test)")
}

func TestLexGenericProgram(t *testing.T) {
    // Not necessarily representative of the actual language, just to test the lexer
    assertLex(t,
        "# Computes and prints the factorial of n\n" +
        "let n = 12; var fact = 1\n" +
        "for var i = 2; i <= n; i += 1\n" +
        "    fact *= i\n" +
        "printfln(\"%d! is %d\", n, fact)\n" +
        "## Random block comment ##",
        "Indentation()",
        "Indentation()", "Keyword(let)", "Identifier(n)", "Symbol(=)", "DecimalIntegerLiteral(12)", "Terminator(;)",
        "Keyword(var)", "Identifier(fact)", "Symbol(=)", "DecimalIntegerLiteral(1)",
        "Indentation()", "Keyword(for)", "Keyword(var)", "Identifier(i)", "Symbol(=)", "DecimalIntegerLiteral(2)", "Terminator(;)",
        "Identifier(i)", "Symbol(<=)", "Identifier(n)", "Terminator(;)",
        "Identifier(i)", "Symbol(+=)", "DecimalIntegerLiteral(1)",
        "Indentation(    )", "Identifier(fact)", "Symbol(*=)", "Identifier(i)",
        "Indentation()", "Identifier(printfln)", "Symbol(()", "StringLiteral(\"%d! is %d\")", "Symbol(,)",
        "Identifier(n)", "Symbol(,)", "Identifier(fact)", "Symbol())",
        "Indentation()",
    )
}

func assertLexNoIndent(t *testing.T, source string, expected ...string) {
    tokenizer := syntax.StringTokenizer(source)
    tokens := []string{}
    if tokenizer.Head().Kind() == syntax.INDENTATION {
        tokenizer.Advance()
    }
    for tokenizer.Has() {
        tokens = append(tokens, tokenizer.Head().String())
        tokenizer.Advance()
    }
    assert.Equal(t, expected, tokens)
}

func assertLex(t *testing.T, source string, expected ...string) {
    tokenizer := syntax.StringTokenizer(source)
    tokens := []string{}
    for tokenizer.Has() {
        tokens = append(tokens, tokenizer.Head().String())
        tokenizer.Advance()
    }
    assert.Equal(t, expected, tokens)
}
