package lang

type Tokenizer struct {
    chars RuneStream
    head []*Token
    position int
    savedPositions []int
    firstToken bool
}

func StringTokenizer(source string) *Tokenizer {
    return &Tokenizer{chars: &StringRuneStream{source: source}, position: 0, firstToken: true}
}

func (this *Tokenizer) Has() bool {
    return this.Head() != EofToken
}

func (this *Tokenizer) Head() *Token {
    for len(this.head) <= this.position {
        this.head = append(this.head, this.next())
    }
    return this.head[this.position]
}

func (this *Tokenizer) Advance() {
    head := this.Head()
    if head != EofToken {
        this.position++
    }
}

func (this *Tokenizer) SavePosition() {
    this.savedPositions = append(this.savedPositions, this.position)
}

func (this *Tokenizer) RestorePosition() {
    this.position = this.savedPositions[len(this.savedPositions) - 1]
    this.DiscardPosition()
}

func (this *Tokenizer) DiscardPosition() {
    this.savedPositions = this.savedPositions[:len(this.savedPositions) - 1]
}

func (this *Tokenizer) next() *Token {
    var token *Token = EofToken
    if (this.firstToken) {
        // First token can be indentation, which in this case
        // is not after a new line
        if isLineWhiteSpace(this.chars.Head()) {
            token = Indentation(collectIndentation(this.chars))
        }
        for consumeIgnored(this.chars) {
            // Remove trailing comments and whitespace
        }
        this.firstToken = false
    }
    for this.chars.Has() && token == EofToken {
        if isNewLineChar(this.chars.Head()) {
            consumeNewLine(this.chars)
            // Just after a new line, try to consume indentation
            if isLineWhiteSpace(this.chars.Head()) {
                token = Indentation(collectIndentation(this.chars))
            }
        } else if this.chars.Head() == ';' {
            // A terminator breaks a line but doesn't need indentation
            this.chars.Advance()
            token = TerminatorToken
        } else if isIdentifierStart(this.chars.Head()) {
            this.chars.Collect()
            identifier := collectIdentifierBody(this.chars)
            // An indentifier can also be a keyword
            if isKeyword(identifier) {
                token = Keyword(identifier)
            } else if isBooleanLiteral(identifier) {
                token = BooleanLiteral(identifier)
            } else {
                token = Identifier(identifier)
            }
        } else if this.chars.Head() == '.' {
            // Could be a float starting with a decimal separator or a symbol
            this.chars.Collect()
            if isDecimalDigit(this.chars.Head()) {
                token = completeFloatLiteralStartingWithDecimalSeparator(this.chars)
            } else {
                token = Symbol(collectSymbol(this.chars))
            }
        } else if isSymbolChar(this.chars.Head()) {
            token = Symbol(collectSymbol(this.chars))
        } else if this.chars.Head() == '"' {
            token = StringLiteral(collectStringLiteral(this.chars))
        } else if isDecimalDigit(this.chars.Head()) {
            token = collectNumberLiteral(this.chars)
        } else {
            panic("Unexpected character")
        }
        for consumeIgnored(this.chars) {
            // Remove trailing comments and whitespace
        }
    }
    return token
}

func collectIdentifierBody(chars RuneStream) []rune {
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
        return true
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
}

func completeLineComment(chars RuneStream) {
    for isPrintChar(chars.Head()) || isLineWhiteSpace(chars.Head()) {
        chars.Advance()
    }
}

func consumeNewLine(chars RuneStream) {
    if chars.Head() == '\r'{
        // CR
        chars.Advance()
        if chars.Head() == '\n' {
            // CR LF
            chars.Advance()
        }
    } else if chars.Head() == '\n' {
        // LF
        chars.Advance()
    }
}

func collectIndentation(chars RuneStream) []rune {
    for isLineWhiteSpace(chars.Head()) {
        chars.Collect()
    }
    return chars.PopCollected()
}

func collectSymbol(chars RuneStream) []rune {
    for isSymbolPrefix(chars.PeekCollected(), chars.Head()) {
        chars.Collect()
    }
    return chars.PopCollected()
}

func collectStringLiteral(chars RuneStream) []rune {
    // Opening "
    if chars.Head() != '"' {
        panic("Expected opening \"")
    }
    chars.Collect()
    // String contents
    for {
        if isPrintChar(chars.Head()) && chars.Head() != '"' && chars.Head() != '\\' {
            chars.Collect()
        } else if isLineWhiteSpace(chars.Head()) {
            chars.Collect()
        } else if collectEscapeSequence(chars) {
            // Nothing to do, it is already collected
        } else {
            // Not part of a string literal body, end here
            break
        }
    }
    // Closing "
    if chars.Head() != '"' {
        panic("Expected closing \"")
    }
    chars.Collect()
    return chars.PopCollected()
}

func collectEscapeSequence(chars RuneStream) bool {
    if chars.Head() != '\\' {
        return false
    }
    chars.Collect()
    if chars.Head() == 'u' {
        chars.Collect()
        // Unicode sequence, collect at least 1 hex digit and at most 8
        if !isHexDigit(chars.Head()) {
            panic("Expected at least one hexadecimal digit in Unicode sequence")
        }
        chars.Collect()
        for i := 1; i < 8 && isHexDigit(chars.Head()); i++ {
            chars.Collect()
        }
        return true
    }
    if RunesContain(ESCAPE_LITERALS, chars.Head()) {
        chars.Collect()
        return true
    }
    return false
}

func collectNumberLiteral(chars RuneStream) *Token {
    // Start with non-decimal integers
    if chars.Head() == '0' {
        chars.Collect()
        if chars.Head() == 'b' || chars.Head() == 'B' {
            // Binary integer
            chars.Collect()
            collectDigitSequence(chars, isBinaryDigit)
            return BinaryIntegerLiteral(chars.PopCollected())
        }
        if chars.Head() == 'x' || chars.Head() == 'X' {
            // Hexadecimal integer
            chars.Collect()
            collectDigitSequence(chars, isHexDigit)
            return HexadecimalIntegerLiteral(chars.PopCollected())
        }
        if !isDecimalDigit(chars.Head()) {
            // Just a zero
            return DecimalIntegerLiteral(chars.PopCollected())
        }
        // Anything else is either a decimal integer or float
    }
    // The number must have a decimal digit sequence next
    collectDigitSequence(chars, isDecimalDigit)
    // Now we can have a decimal separator here, making it a float
    if chars.Head() == '.' {
        chars.Collect()
        // There can be more digits after the decimal separator
        if isDecimalDigit(chars.Head()) {
            collectDigitSequence(chars, isDecimalDigit)
        }
        // We can have an optional exponent
        collectFloatLiteralExponent(chars)
        return FloatLiteral(chars.PopCollected())
    }
    // Or we can have an exponent marker, again making it a float
    if collectFloatLiteralExponent(chars) {
        return FloatLiteral(chars.PopCollected())
    }
    // Else it's a decimal integer and there's nothing more to do
    return DecimalIntegerLiteral(chars.PopCollected())
}

func completeFloatLiteralStartingWithDecimalSeparator(chars RuneStream) *Token {
    // Must have a decimal digit sequence next after the decimal
    collectDigitSequence(chars, isDecimalDigit)
    // We can have an optional exponent
    collectFloatLiteralExponent(chars)
    return FloatLiteral(chars.PopCollected())
}

func collectFloatLiteralExponent(chars RuneStream) bool {
    // Only collect the exponent if it exists
    if chars.Head() != 'e' && chars.Head() != 'E' {
        return false
    }
    chars.Collect()
    // It's an optional sign
    if chars.Head() == '-' || chars.Head() == '+' {
        chars.Collect()
    }
    // Followed by a decimal digit sequence
    collectDigitSequence(chars, isDecimalDigit)
    return true
}

func collectDigitSequence(chars RuneStream, isDigit func(rune) bool) {
    if !isDigit(chars.Head()) {
        panic("Expected a digit")
    }
    chars.Collect()
    for {
        if chars.Head() == '_' {
            chars.Collect()
            for chars.Head() == '_' {
                chars.Collect()
            }
            if !isDigit(chars.Head()) {
                panic("Expected a digit")
            }
            chars.Collect()
        } else if isDigit(chars.Head()) {
            chars.Collect()
        } else {
            break
        }
    }
}

func isIdentifierStart(c rune) bool {
    return c == '_' || isLetter(c)
}

func isIdentifierBody(c rune) bool {
    return isIdentifierStart(c) || isDecimalDigit(c)
}

func isLetter(c rune) bool {
    return c >= 'A' && c <= 'Z' || c >= 'a' && c <= 'z'
}

func isBinaryDigit(c rune) bool {
    return c == '0' || c == '1'
}

func isDecimalDigit(c rune) bool {
    return isBinaryDigit(c) || c >= '2' && c <= '9'
}

func isHexDigit(c rune) bool {
    return isDecimalDigit(c) || c >= 'A' && c <= 'F' || c >= 'a' && c <= 'f'
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

var SYMBOLS = [][]rune{
   []rune("!"), []rune("@"), []rune("%"), []rune("?"), []rune("&"), []rune("*"), []rune("("), []rune(")"), []rune("-"), []rune("="),
   []rune("+"), []rune("/"), []rune("^"), []rune(":"), []rune("<"), []rune(">"), []rune("["), []rune("]"), []rune("{"), []rune("}"),
   []rune("."), []rune(","), []rune("~"), []rune("|"), []rune("<<"), []rune(">>"), []rune(">>>"), []rune("<="), []rune(">="), []rune("<:"),
   []rune(">:"), []rune("<<:"), []rune(">>:"), []rune("<:>"), []rune("!="), []rune("::"), []rune("!:"), []rune("&&"), []rune("^^"),
   []rune("||"), []rune("**="), []rune("*="), []rune("/="), []rune("%="), []rune("+="),[]rune("-="), []rune("<<="), []rune(">>="),
   []rune(">>>="), []rune("&="), []rune("^="), []rune("|="), []rune("&&="), []rune("^^="),[]rune("||="), []rune("~="), []rune("="),
   []rune("=="), []rune("==="), []rune("!=="),
}

func isSymbolChar(c rune) bool {
    for _, symbol := range SYMBOLS {
        if c == symbol[0] {
            return true
        }
    }
    return false
}

func isSymbolPrefix(cs []rune, c rune) bool {
    prefixLength := len(cs) + 1
    outer:
    for _, symbol := range SYMBOLS {
        symbolLength := len(symbol)
        if prefixLength > symbolLength {
            continue outer
        }
        for i := 0; i < prefixLength - 1; i++ {
            if cs[i] != symbol[i] {
                continue outer
            }
        }
        if c == symbol[prefixLength - 1] {
            return true
        }
    }
    return false
}

var KEYWORDS = [][]rune{
    []rune("when"), []rune("with"), []rune("then"), []rune("match"), []rune("if"), []rune("else"), []rune("for"), []rune("for_rev"), []rune("while"),
    []rune("do"), []rune("try"), []rune("catch"), []rune("finally"), []rune("let"), []rune("var"), []rune("class"), []rune("void"), []rune("break"),
    []rune("continue"), []rune("throw"), []rune("static"), []rune("import"), []rune("package"), []rune("new"), []rune("throws"), []rune("public"),
    []rune("return"), []rune("this"), []rune("super"),
}

func isKeyword(cs []rune) bool {
    for _, keyword := range KEYWORDS {
        if RunesEquals(cs, keyword) {
            return true
        }
    }
    return false
}

var FALSE_LITERAL = []rune("false")
var TRUE_LITERAL = []rune("true")

func isBooleanLiteral(cs []rune) bool {
    return RunesEquals(cs, FALSE_LITERAL) || RunesEquals(cs, TRUE_LITERAL)
}

var ESCAPE_LITERALS = []rune{
    'a', 'b', 't', 'n', 'v', 'f', 'r', '"', '\\',
}
