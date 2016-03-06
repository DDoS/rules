package lang

import (
    "unicode/utf8"
)

type RuneStream interface {
    Has() bool
    Head() rune
    Advance()
    Count() uint
    Collect()
    PeekCollected() []rune
    PopCollected() []rune
}

type StringRuneStream struct {
    source string
    headRune rune
    ahead bool
    count uint
    collected []rune
}

func (this *StringRuneStream) Has() bool {
    return len(this.source) > 0 || this.ahead && this.headRune != '\u0004'
}

func (this *StringRuneStream) Head() rune {
    if !this.ahead {
        if this.Has() {
            char, size := utf8.DecodeRuneInString(this.source)
            this.headRune = char
            this.source = this.source[size:]
        } else {
            // EOT
            this.headRune = '\u0004'
        }
        this.ahead = true
    }
    return this.headRune
}

func (this *StringRuneStream) Count() uint {
    return this.count
}

func (this *StringRuneStream) Advance() {
    this.Head()
    this.ahead = false
    this.count++
}

func (this *StringRuneStream) Collect() {
    this.Advance()
    this.collected = append(this.collected, this.headRune)
}

func (this *StringRuneStream) PeekCollected() []rune {
    return this.collected
}

func (this *StringRuneStream) PopCollected() []rune {
    collected := make([]rune, len(this.collected))
    copy(collected, this.collected)
    this.collected = nil
    return collected
}
