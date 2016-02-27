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
            // Nothing to do here, skip all of it
        }
        if isIdentifierStart(this.chars.Head()) {
            this.chars.Collect()
            return &Identifier{completeIdentifier(this.chars)}
        }
    }
    return EOF;
}

func completeIdentifier(chars RuneStream) []rune {
    for isIdentifierBody(chars.Head()) {
        chars.Collect()
    }
    return chars.PopCollected()
}

func consumeIgnored(chars RuneStream) bool {
    if isLineWhiteSpace(chars.Head()) {
        // Consume a line whitespace character
        chars.Advance()
        return true
    }
    if chars.Head() == '#' {
        // Consume a comment
        chars.Advance()
        if (chars.Head() == '#') {
            chars.Advance()
            completeBlockComment(chars)
        } else {
            completeLineComment(chars)
        }
        return true
    }
    if chars.Head() == '\\' {
        // Consume an escaped new line
        chars.Advance()
        if !isNewLineChar(chars.Head()) {
            panic("Expected new line character")
        }
        chars.Advance()
        // Consume more escaped new lines
        for isNewLineChar(chars.Head()) {
            chars.Advance()
        }
        return true;
    }
    return false
}

func completeBlockComment(chars RuneStream) {
    // Count and consume leading # symbols
    leading := 2
    for chars.Head() == '#' {
        leading++
        chars.Advance()
    }
    // Consume print and white space characters
    // and look for a matching count of consecutive #
    trailing := 0
    for trailing < leading {
        if chars.Head() == '#' {
            trailing++
        } else if isPrintChar(chars.Head()) || isWhiteSpace(chars.Head()) {
            trailing = 0
        } else {
            panic("Unexpected character")
        }
        chars.Advance()
    }
    if trailing != leading {
        panic("Block comment is not closed")
    }
}

func completeLineComment(chars RuneStream) {
    for isPrintChar(chars.Head()) || isLineWhiteSpace(chars.Head()) {
        chars.Advance()
    }
    if !consumeLineTerminator(chars) {
        panic("Expected line terminator")
    }
}

func consumeLineTerminator(chars RuneStream) bool {
    if chars.Head() == 0x4 {
        // EOT
        return true
    }
    if chars.Head() == '\r' {
        // CR
        chars.Advance()
        if chars.Head() == '\n' {
            // CR LF
            chars.Advance()
        }
        return true;
    }
    if chars.Head() == '\n' {
        // LF
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
    return c == '\n' || c == '\r'
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
