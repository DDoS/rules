package lang_test

import (
    "fmt"
    "testing"
    "github.com/stretchr/testify/assert"
    "github.com/michael-golfi/rules/lang"
)

func TestLexIdentifier(t *testing.T) {
    assertLex(t, "t", "Identifier(t)")
    assertLex(t, "t12", "Identifier(t12)")
    assertLex(t, "_", "Identifier(_)")
    assertLex(t, "_12", "Identifier(_12)")
    assertLex(t, "test", "Identifier(test)")
}

func TestLexIndentation(t *testing.T) {
    assertLex(t, "    test", "Indentation(    )", "Identifier(test)")
    assertLex(t, "\ntest", "Identifier(test)")
    assertLex(t, "\r\ntest", "Identifier(test)")
    assertLex(t, "\r    test", "Indentation(    )", "Identifier(test)")
    assertLex(t, "\r\ttest", "Indentation(\t)", "Identifier(test)")
    assertLex(t, "test\nyou", "Identifier(test)", "Identifier(you)")
    assertLex(t, "hello\n you", "Identifier(hello)", "Indentation( )", "Identifier(you)")
    assertLex(t, " hello\n you", "Indentation( )", "Identifier(hello)", "Indentation( )", "Identifier(you)")
    assertLex(t, " \\\ntest", "Indentation( )", "Identifier(test)")
}

func TestLexTerminator(t *testing.T) {
    assertLex(t, "test;that", "Identifier(test)", "Terminator(;)", "Identifier(that)")
}

func TestLexKeyword(t *testing.T) {
    for _, keyword := range lang.KEYWORDS {
        stringKeword := string(keyword)
        assertLex(t, stringKeword, fmt.Sprintf("Keyword(%s)", stringKeword))
    }
}

func TestLexSymbol(t *testing.T) {
    for _, symbol := range lang.SYMBOLS {
        stringSymbol := string(symbol)
        assertLex(t, stringSymbol, fmt.Sprintf("Symbol(%s)", stringSymbol))
    }
}

func TestLexBooleanLiteral(t *testing.T) {
    assertLex(t, "false", "BooleanLiteral(false)")
    assertLex(t, "true", "BooleanLiteral(true)")
}

func TestLextStringLiteral(t *testing.T) {
    assertLex(t, "\"test\"", "StringLiteral(\"test\")")
    assertLex(t, "\"  \"", "StringLiteral(\"  \")")
    assertLex(t, "\"  t  \"", "StringLiteral(\"  t  \")")
    assertLex(t, "\"te\\nst\"", "StringLiteral(\"te\\nst\")")
    assertLex(t, "\"te\\\"nst\"", "StringLiteral(\"te\\\"nst\")")
    assertLex(t, "\"te\\\\st\"", "StringLiteral(\"te\\\\st\")")
    assertLex(t, "\"te\\\\nst\"", "StringLiteral(\"te\\\\nst\")")
    assertLex(t, "\"\\u00000000\"", "StringLiteral(\"\\u00000000\")")
    assertLex(t, "\"\\u0\"", "StringLiteral(\"\\u0\")")
    assertLex(t, "\"\\u214ade\"", "StringLiteral(\"\\u214ade\")")
    assertLex(t, "\"\\u214ader\"", "StringLiteral(\"\\u214ader\")")
}

func TestLexBinaryIntegerLiteral(t *testing.T) {
    assertLex(t, "0b0", "BinaryIntegerLiteral(0b0)")
    assertLex(t, "0b11", "BinaryIntegerLiteral(0b11)")
    assertLex(t, "0B110101", "BinaryIntegerLiteral(0B110101)")
    assertLex(t, "0b1101_0001", "BinaryIntegerLiteral(0b1101_0001)")
    assertLex(t, "0b1101__0001", "BinaryIntegerLiteral(0b1101__0001)")
    assertLex(t, "0b1101_0100_0001", "BinaryIntegerLiteral(0b1101_0100_0001)")
    assertLex(t, "0b1101_0100____0001", "BinaryIntegerLiteral(0b1101_0100____0001)")
}

func TestLexDecimalIntegerLiteral(t *testing.T) {
    assertLex(t, "0", "DecimalIntegerLiteral(0)")
    assertLex(t, "012", "DecimalIntegerLiteral(012)")
    assertLex(t, "564", "DecimalIntegerLiteral(564)")
    assertLex(t, "5_000", "DecimalIntegerLiteral(5_000)")
    assertLex(t, "5__000", "DecimalIntegerLiteral(5__000)")
    assertLex(t, "5_000_000", "DecimalIntegerLiteral(5_000_000)")
    assertLex(t, "5_000____000", "DecimalIntegerLiteral(5_000____000)")
}

func TestLexHexadecimalIntegerLiteral(t *testing.T) {
    assertLex(t, "0x0", "HexadecimalIntegerLiteral(0x0)")
    assertLex(t, "0xAf", "HexadecimalIntegerLiteral(0xAf)")
    assertLex(t, "0XA24E4", "HexadecimalIntegerLiteral(0XA24E4)")
    assertLex(t, "0xDEAD_BEEF", "HexadecimalIntegerLiteral(0xDEAD_BEEF)")
    assertLex(t, "0x2192__CAFE", "HexadecimalIntegerLiteral(0x2192__CAFE)")
    assertLex(t, "0xBABE_291c_13b2", "HexadecimalIntegerLiteral(0xBABE_291c_13b2)")
    assertLex(t, "0x4235_1232____54fd3", "HexadecimalIntegerLiteral(0x4235_1232____54fd3)")
}

func TestLexFloatLiteral(t *testing.T) {
    assertLex(t, "1_000.0", "FloatLiteral(1_000.0)");
    assertLex(t, ".1", "FloatLiteral(.1)");
    assertLex(t, ".143_21", "FloatLiteral(.143_21)");
    assertLex(t, "1e2", "FloatLiteral(1e2)");
    assertLex(t, "1.0e2", "FloatLiteral(1.0e2)");
    assertLex(t, "113.211e21", "FloatLiteral(113.211e21)");
    assertLex(t, ".1e2", "FloatLiteral(.1e2)");
    assertLex(t, "1e-2", "FloatLiteral(1e-2)");
    assertLex(t, "1.65e+2", "FloatLiteral(1.65e+2)");
    assertLex(t, "1.0e-2", "FloatLiteral(1.0e-2)");
    assertLex(t, ".1e+2", "FloatLiteral(.1e+2)");
    assertLex(t, "1_113.291_121e9", "FloatLiteral(1_113.291_121e9)");
}

func TestLexIgnored(t *testing.T) {
    assertLex(t, "test\\\nyou", "Identifier(test)", "Identifier(you)")
    assertLex(t, "#A \tcomment!\ntest", "Identifier(test)")
    assertLex(t, "#Testing #some characters in \\comments\ntest", "Identifier(test)")
    assertLex(t, "## Comment\\test ## test", "Identifier(test)")
    assertLex(t, "## Two ## #Comments\n test", "Indentation( )", "Identifier(test)")
    assertLex(t, "## Hello \n World \r\t\n ##test", "Identifier(test)")
    assertLex(t, "### You\nCan ## Nest\nComments # like this ## ###test", "Identifier(test)")
}

func TestLexGenericProgram(t *testing.T) {
    // Not necessarily representative of the actual language, just to test the lexer
    assertLex(t,
        "# Computes and prints the factorial of n\n" +
        "let n := 12; var fact := 1\n" +
        "for var i := 2; i <= n; i += 1\n" +
        "    fact *= i\n" +
        "printfln(\"%d! is %d\", n, fact)\n" +
        "## Random block comment ##",
        "Keyword(let)", "Identifier(n)", "Symbol(:=)", "DecimalIntegerLiteral(12)", "Terminator(;)",
        "Keyword(var)", "Identifier(fact)", "Symbol(:=)", "DecimalIntegerLiteral(1)",
        "Keyword(for)", "Keyword(var)", "Identifier(i)", "Symbol(:=)", "DecimalIntegerLiteral(2)", "Terminator(;)",
        "Identifier(i)", "Symbol(<=)", "Identifier(n)", "Terminator(;)",
        "Identifier(i)", "Symbol(+=)", "DecimalIntegerLiteral(1)",
        "Indentation(    )", "Identifier(fact)", "Symbol(*=)", "Identifier(i)",
        "Identifier(printfln)", "Symbol(()", "StringLiteral(\"%d! is %d\")", "Symbol(,)", "Identifier(n)", "Symbol(,)", "Identifier(fact)", "Symbol())",
    )
}

func assertLex(t *testing.T, source string, expected ...string) {
    tokenizer := lang.StringTokenizer(source)
    tokens := []string{}
    for tokenizer.Has() {
        tokens = append(tokens, tokenizer.Head().String())
        tokenizer.Advance()
    }
    assert.Equal(t, expected, tokens)
}
