package lang

import "fmt"

type Kind uint

const (
        INDENTATION Kind = iota
        TERMINATOR
        IDENTIFIER
        KEYWORD
        SYMBOL
        EOF
)

type Token struct {
    Source []rune
    Kind Kind
}

func Indentation(source []rune) *Token {
    return &Token{source, INDENTATION}
}

var TerminatorToken *Token = &Token{[]rune{';'}, TERMINATOR}

func Identifier(source []rune) *Token {
    return &Token{source, IDENTIFIER}
}

func Keyword(source []rune) *Token {
    return &Token{source, KEYWORD}
}

func Symbol(source []rune) *Token {
    return &Token{source, SYMBOL}
}

var EofToken *Token = &Token{[]rune{0x4}, EOF}

func (token *Token) String() string {
    return fmt.Sprintf("%s(%s)", token.Kind.String(), string(token.Source))
}

func (kind Kind) String() string {
    switch kind {
    case INDENTATION:
        return "Indentation"
    case TERMINATOR:
        return "Terminator"
    case IDENTIFIER:
        return "Identifier"
    case KEYWORD:
        return "Keyword"
    case SYMBOL:
        return "Symbol"
    case EOF:
        return "EOF"
    }
    panic(fmt.Sprintf("Unknown token kind %d", kind))
}
