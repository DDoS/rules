package lang;

type Token interface {
    Source() []rune
}

type Identifier struct {
    source []rune
}

func (this *Identifier) Source() []rune {
    return this.source
}

var EOF *EndOfFile = &EndOfFile{};

type EndOfFile struct {
}

var emptySource = []rune{}

func (this *EndOfFile) Source() []rune {
    return emptySource
}
