package lang

var EOF *EndOfFile = &EndOfFile{}

type Token interface {
    Source() []rune
}

type Indentation struct {
    source []rune
}

type Identifier struct {
    source []rune
}

type EndOfFile struct {
}

func (this *Indentation) Source() []rune {
    return this.source
}

func (this *Identifier) Source() []rune {
    return this.source
}

func (this *EndOfFile) Source() []rune {
    return []rune{0x4}
}
