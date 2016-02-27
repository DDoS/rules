package lang_test;

import (
    "testing"
    "github.com/stretchr/testify/assert"
    "github.com/michael-golfi/rules/lang"
)

func TestLexIdentifier(t *testing.T) {
    assertLex(t, "test", "test")
}

func TestLexIndentation(t *testing.T) {
    assertLex(t, "\ntest", "", "test")
    assertLex(t, "\r\ntest", "", "test")
    assertLex(t, "\r    test", "    ", "test")
    assertLex(t, "\r\ttest", "\t", "test")
    assertLex(t, "test\nyou", "test", "", "you")
    assertLex(t, "hello\n you", "hello", " ", "you")
}

func TestLexIgnored(t *testing.T) {
    assertLex(t, "test\\\nyou", "test", "you")
    assertLex(t, "#A \tcomment!\ntest", "", "test")
    assertLex(t, "#Testing #some characters in \\comments\ntest", "", "test")
    assertLex(t, "## Comment\\test ## test", "test")
    assertLex(t, "## Two ## #Comments\n test", " ", "test")
    assertLex(t, "## Hello \n World \r\t\n ##test", "test")
    assertLex(t, "### You\nCan ## Nest\nComments # like this ## ###test", "test")
}

func assertLex(t *testing.T, source string, expected ...string) {
    tokenizer := lang.StringTokenizer(source)
    tokens := []string{}
    for tokenizer.Has() {
        tokens = append(tokens, string(tokenizer.Head().Source()))
        tokenizer.Advance()
    }
    assert.Equal(t, expected, tokens)
}
