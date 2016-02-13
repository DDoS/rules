package lang;

type Tokenizer struct {
    chars RuneStream
}

func StringTokenizer(source string) *Tokenizer {
    return &Tokenizer{&StringRuneStream{source}}
}

func (t *Tokenizer) Next() Token {
    return &Identifier{"test"}
}
