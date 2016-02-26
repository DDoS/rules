package lang_test;

import (
    "testing"
    "github.com/stretchr/testify/assert"
    "github.com/michael-golfi/rules/lang"
)

func TestLexIdentifier(t *testing.T) {
    assert.Equal(t, "test", lexOneToken("test"))
}

func TestLexIgnored(t *testing.T) {
    assert.Equal(t, "test", lexOneToken(" test"))
    assert.Equal(t, "test", lexOneToken("   test"))
    assert.Equal(t, "test", lexOneToken("\ttest"))
    assert.Equal(t, "test", lexOneToken("\t \ttest"))
    assert.Equal(t, "test", lexOneToken("test"))
    assert.Equal(t, "test", lexOneToken("#A \tcomment!\ntest"))
    assert.Equal(t, "test", lexOneToken("#A \tcomment!\r\ntest"))
    assert.Equal(t, "test", lexOneToken("#Testing #some characters in \\comments\ntest"))
    assert.Equal(t, "test", lexOneToken("\\\ntest"))
    assert.Equal(t, "test", lexOneToken("\\\n\rtest"))
    assert.Equal(t, "test", lexOneToken("## Comment\\test ##test"))
    assert.Equal(t, "test", lexOneToken("## Two ## #Comments\n test"))
    assert.Equal(t, "test", lexOneToken("## Hello \n World \r\t\n ##test"))
    assert.Equal(t, "test", lexOneToken("### You\nCan ## Nest\nComments # like this ## ###test"))
}

func lexOneToken(source string) string {
    return string(lang.StringTokenizer(source).Head().Source())
}
