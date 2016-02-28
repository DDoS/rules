package lang_test;

import (
    "fmt"
    "math/rand"
    "testing"
    "github.com/stretchr/testify/assert"
    "github.com/michael-golfi/rules/lang"
)

func TestLexIdentifier(t *testing.T) {
    assertLex(t, "t", "Identifier(t)")
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

func testLexTerminator(t *testing.T) {
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
        compositeSymbol := []rune{symbol}
        length := rand.Intn(2)
        for i := 0; i < length; i++ {
            compositeSymbol = append(compositeSymbol, lang.SYMBOLS[rand.Intn(len(lang.SYMBOLS))])
        }
        stringSymbol := string(compositeSymbol)
        assertLex(t, stringSymbol, fmt.Sprintf("Symbol(%s)", stringSymbol))
    }
}

func testLexBooleanLiteral(t *testing.T) {
    assertLex(t, "false", "BooleanLiteral(false)")
    assertLex(t, "true", "BooleanLiteral(true)")
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

func assertLex(t *testing.T, source string, expected ...string) {
    tokenizer := lang.StringTokenizer(source)
    tokens := []string{}
    for tokenizer.Has() {
        tokens = append(tokens, string(tokenizer.Head().String()))
        tokenizer.Advance()
    }
    assert.Equal(t, expected, tokens)
}
