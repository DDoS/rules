package lang;

type Tokenizer struct {
    chars RuneStream
    headToken Token
    ahead bool
}

func StringTokenizer(source string) *Tokenizer {
    return &Tokenizer{chars: &StringRuneStream{source: source}}
}

func (this *Tokenizer) Has() bool {
    return this.Head() != EOF
}

func (this *Tokenizer) Head() Token {
    if !this.ahead {
        this.headToken = this.next()
        this.ahead = true
    }
    return this.headToken
}

func (this *Tokenizer) Advance() {
    this.Head()
    this.ahead = false
}

func (this *Tokenizer) next() Token {
    if this.chars.Has() {
        for consumeIgnored(this.chars) {
            // Nothing to do here
        }
        if isIdentifierStart(this.chars.Head()) {
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

func consumeIgnored(chars RuneStream) bool {
    if chars.Has() {
        if isLineWhiteSpace(chars.Head()) {
            chars.Advance()
            return true
        } else if chars.Head() == '#' {
            chars.Advance()
            completeLineComment(chars)
            return true
        }
    }
    return false
}

func completeLineComment(chars RuneStream) {
    for chars.Has() && (isPrintChar(chars.Head()) || isLineWhiteSpace(chars.Head())) {
        chars.Advance()
    }
    if !chars.Has() || consumeLineTerminator(chars) {
        return
    }
    panic("Expected end of line comment")
}

func consumeLineTerminator(chars RuneStream) bool {
    if !chars.Has() {
        return false
    }
    if chars.Head() == '\r' {
        chars.Advance()
        if chars.Head() == '\n' {
            chars.Advance()
        }
        return true;
    } else if chars.Head() == '\n' {
        chars.Advance()
        return true;
    }
    return false;
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

func isPrintChar(c rune) bool {
    return c >= '!' && c <= '~'
}

func isNewLineChar(c rune) bool {
    return c == '\f' || c == '\n' || c == '\r'
}

func isLineWhiteSpace(c rune) bool {
    return c == ' ' || c == '\t'
}

func isWhiteSpace(c rune) bool {
    return isNewLineChar(c) || isLineWhiteSpace(c)
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
