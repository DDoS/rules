package lang

import (
    "os"
    "bufio"
    "unicode/utf8"
)

type RuneStream interface {
    Has() bool
    Next() rune
}

type StringRuneStream struct {
    source string
}

type ReadLineRuneStream struct {
    buffer *bufio.Reader
    headRune rune
    ahead bool
}

type RuneReader struct {
    RuneStream
    headRune rune
    ahead bool
    count uint
    collected []rune
}

func StringRuneReader(source string) *RuneReader {
    return &RuneReader{RuneStream: &StringRuneStream{source}}
}

func (this *StringRuneStream) Has() bool {
    return len(this.source) > 0
}

func (this *StringRuneStream) Next() rune {
    char, size := utf8.DecodeRuneInString(this.source)
    this.source = this.source[size:]
    return char
}

func ReadLineRuneReader(file *os.File) *RuneReader {
    return &RuneReader{RuneStream: &ReadLineRuneStream{buffer: bufio.NewReader(file)}}
}

func (this *ReadLineRuneStream) Has() bool {
    return this.Head() != '\u0004'
}

func (this *ReadLineRuneStream) Next() rune {
    char := this.Head()
    this.ahead = false
    return char
}

func (this *ReadLineRuneStream) Head() rune {
    if !this.ahead {
        char, _, err := this.buffer.ReadRune()
        if err == nil && char != '\n' {
            this.headRune = char
        } else {
            this.headRune = '\u0004'
        }
        this.ahead = true
    }
    return this.headRune
}

func (this *RuneReader) Has() bool {
    return this.RuneStream.Has() || this.ahead && this.headRune != '\u0004'
}

func (this *RuneReader) Head() rune {
    if !this.ahead {
        if this.RuneStream.Has() {
            this.headRune = this.Next()
        } else {
            this.headRune = '\u0004'
        }
        this.ahead = true
    }
    return this.headRune
}

func (this *RuneReader) Count() uint {
    return this.count
}

func (this *RuneReader) Advance() {
    this.Head()
    this.ahead = false
    this.count++
}

func (this *RuneReader) Collect() {
    this.Advance()
    this.collected = append(this.collected, this.headRune)
}

func (this *RuneReader) PeekCollected() []rune {
    return this.collected
}

func (this *RuneReader) PopCollected() []rune {
    collected := make([]rune, len(this.collected))
    copy(collected, this.collected)
    this.collected = nil
    return collected
}
