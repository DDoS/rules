package lang;

type Token interface {
    Source() string
}

type Identifier struct {
    source string
}

func (identifier *Identifier) Source() string {
    return identifier.source
}
