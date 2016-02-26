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
}

func lexOneToken(source string) string {
    return string(lang.StringTokenizer(source).Head().Source())
}
