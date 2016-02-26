package lang;

import (
    "unicode/utf8"
)

type RuneStream interface {
    Has() bool
    Head() rune
    Advance()
    Collect()
    PopCollected() []rune
}

type StringRuneStream struct {
    source string
    headRune rune
    ahead bool
    collected []rune
}

func (this *StringRuneStream) Has() bool {
    return len(this.source) > 0
}

func (this *StringRuneStream) Head() rune {
    if !this.ahead {
        if !this.Has() {
            panic("Empty rune stream")
        }
        char, size := utf8.DecodeRuneInString(this.source)
        this.headRune = char
        this.source = this.source[size:]
        this.ahead = true
    }
    return this.headRune
}

func (this *StringRuneStream) Advance() {
    this.Head()
    this.ahead = false
}

func (this *StringRuneStream) Collect() {
    this.Advance()
    this.collected = append(this.collected, this.headRune)
}

func (this *StringRuneStream) PopCollected() []rune {
    collected := make([]rune, len(this.collected))
    copy(collected, this.collected)
    this.collected = nil
    return collected
}
