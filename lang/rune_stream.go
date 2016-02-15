package lang;

import "unicode/utf8"

type RuneStream interface {
    Has() bool
    Next() rune
}

type StringRuneStream struct {
    source string
}

func (stream *StringRuneStream) Has() bool {
    return len(stream.source) > 0
}

func (stream *StringRuneStream) Next() rune {
    char, size := utf8.DecodeRuneInString(stream.source)
    stream.source = stream.source[size:]
    return char
}
