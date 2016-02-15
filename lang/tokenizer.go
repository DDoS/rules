package lang;

import (
    "fmt"
)

type Tokenizer struct {
    chars RuneStream
}

func StringTokenizer(source string) *Tokenizer {
    return &Tokenizer{&StringRuneStream{source: source}}
}

func (this *Tokenizer) Next() Token {
    if this.chars.Has() {
        if (isIdentifierStart(this.chars.Head())) {
            this.chars.Collect()
            return &Identifier{completeIdentifier(this.chars)}
        }
    }
    return EOF;
}

func completeIdentifier(chars RuneStream) []rune {
    for chars.Has() && isIdentifierBody(chars.Head()) {
        chars.Collect()
    }
    return chars.PopCollected()
}

func isIdentifierStart(c rune) bool {
    return c == '_' || isLetter(c)
}

func isIdentifierBody(c rune) bool {
    return isIdentifierStart(c) || isDigit(c)
}

func isLetter(c rune) bool {
    return c >= 'A' && c <= 'Z' || c >= 'a' && c <= 'z'
}

func isBinaryDigit(c rune) bool {
    return c == '0' || c == '1'
}

func isDigit(c rune) bool {
    return isBinaryDigit(c) || c >= '2' && c <= '9'
}

func isHexDigit(c rune) bool {
    return isDigit(c) || c >= 'A' && c <= 'F' || c >= 'a' && c <= 'f'
}

var SYMBOLS = [...]rune{
    '!', '@', '#', '%', '?', '&', '*', '(', ')', '-', '=', '+', '/', '^', ';', ':', '<', '>', '[', ']', '.', ',', '~',
}

func isSymbol(c rune) bool {
    for _, symbol := range SYMBOLS {
        if c == symbol {
            return true
        }
    }
    return false
}

var KEYWORDS = [...][]rune{
    []rune("when"), []rune("with"), []rune("then"), []rune("match"), []rune("if"), []rune("else"), []rune("for"), []rune("for_rev"), []rune("while"),
    []rune("do"), []rune("try"), []rune("catch"), []rune("finally"), []rune("let"), []rune("var"), []rune("class"), []rune("void"), []rune("break"),
    []rune("continue"), []rune("throw"), []rune("bool"), []rune("byte"), []rune("char"), []rune("short"), []rune("int"), []rune("long"), []rune("float"),
    []rune("double"), []rune("static"), []rune("import"), []rune("package"), []rune("new"), []rune("is"), []rune("throws"), []rune("public"), []rune("return"),
    []rune("this"), []rune("super"), []rune("true"), []rune("false"),
}

func isKeyword(cs []rune) bool {
    outer:
    for _, keyword := range KEYWORDS {
        if len(cs) != len(keyword) {
            continue outer
        }
        for i := range cs {
            if cs[i] != keyword[i] {
                continue outer
            }
        }
        return true
    }
    return false
}
