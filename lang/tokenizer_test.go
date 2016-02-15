package lang_test;

import (
    "testing"
    "github.com/stretchr/testify/assert"
    "github.com/michael-golfi/rules/lang"
)

func TestLexIdentifier(t *testing.T) {
    tokenizer := lang.StringTokenizer("test")
    assert.Equal(t, "test", string(tokenizer.Next().Source()))
}
