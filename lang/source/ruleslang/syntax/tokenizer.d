module ruleslang.syntax.tokenizer;

import std.algorithm.searching : canFind;

import ruleslang.syntax.dchars;
import ruleslang.syntax.source;
import ruleslang.syntax.token;

public class Tokenizer {
    private DCharReader chars;
    private Token[] headTokens;
    private uint position = 0;
    private uint[] savedPositions;
    private bool firstToken = true;

    public this(DCharReader chars) {
        this.chars = chars;
        headTokens = new Token[0];
        headTokens.reserve(32);
        savedPositions = new uint[0];
        savedPositions.reserve(32);
    }

    public bool has() {
        return head().getKind() != Kind.EOF;
    }

    public Token head() {
        while (headTokens.length <= position) {
            headTokens ~= next();
        }
        return headTokens[position];
    }

    public void advance() {
        if (head().getKind() != Kind.EOF) {
            position++;
        }
    }

    public void savePosition() {
        savedPositions ~= position;
    }

    public void restorePosition() {
        position = savedPositions[$ - 1];
        discardPosition();
    }

    public void discardPosition() {
        savedPositions.length--;
    }

    public Token next() {
        Token token = null;
        if (firstToken && chars.has()) {
            // First token is indentation, which in this case
            // is not after a new line
            auto start = chars.count;
            auto indentation = chars.collectIndentation();
            auto end = chars.count - 1 < start ? start : chars.count - 1;
            token = new Indentation(indentation, start, end);
            while (chars.consumeIgnored()) {
                // Remove trailing comments and whitespace
            }
            firstToken = false;
        }
        while (chars.has() && token is null) {
            if (chars.head().isNewLineChar()) {
                auto start = chars.count;
                chars.consumeNewLine();
                // Just after a new line, consume indentation of next line
                auto indentation = chars.collectIndentation();
                auto end = chars.count - 1;
                token = new Indentation(indentation, start, end);
            } else if (chars.head() == ';') {
                // A terminator breaks a line but doesn't need indentation
                chars.advance();
                token = new Terminator(chars.count - 1);
            } else if (chars.head().isIdentifierStart()) {
                auto position = chars.count;
                chars.collect();
                auto identifier = collectIdentifierBody(chars);
                // An indentifier can also be a keyword
                if (identifier.isKeyword()) {
                    token = new Keyword(identifier, position);
                } else if (identifier == NULL_LITERAL) {
                    token = new NullLiteral(position);
                } else if (identifier.isBooleanLiteral()) {
                    token = new BooleanLiteral(identifier, position);
                } else {
                    token = new Identifier(identifier, position);
                }
            } else if (chars.head() == '.') {
                // Could be a float starting with a decimal separator or a symbol
                auto position = chars.count;
                chars.collect();
                if (chars.head().isDecimalDigit()) {
                    token = chars.completeFloatLiteralStartingWithDecimalSeparator(position);
                } else {
                    token = newSymbol(chars.collectSymbol(), position);
                }
            } else if (chars.head().isSymbolChar()) {
                auto position = chars.count;
                token = newSymbol(chars.collectSymbol(), position);
            } else if (chars.head() == '"') {
                auto position = chars.count;
                token = new StringLiteral(chars.collectStringLiteral(), position);
            } else if (chars.head() == '\'') {
                auto position = chars.count;
                token = new CharacterLiteral(chars.collectCharacterLiteral(), position);
            } else if (chars.head().isDecimalDigit()) {
                token = chars.collectNumberLiteral();
            } else {
                throw new SourceException("Unexpected character", chars.head(), chars.count);
            }
            while (chars.consumeIgnored()) {
                // Remove trailing comments and whitespace
            }
        }
        return token is null ? new Eof(chars.count - 1) : token;
    }
}

private dstring collectIdentifierBody(DCharReader chars) {
    while (chars.head().isIdentifierBody()) {
        chars.collect();
    }
    return chars.popCollected();
}

private bool consumeIgnored(DCharReader chars) {
    if (chars.head().isLineWhiteSpace()) {
        // Consume a line whitespace character
        chars.advance();
        return true;
    }
    if (chars.head() == '#') {
        // Consume a comment
        chars.advance();
        if (chars.head() == '#') {
            chars.advance();
            chars.completeBlockComment();
        } else {
            chars.completeLineComment();
        }
        return true;
    }
    if (chars.head() == '\\') {
        // Consume an escaped new line
        chars.advance();
        if (!chars.head().isNewLineChar()) {
            throw new SourceException("Expected new line character", chars.head(), chars.count);
        }
        chars.advance();
        // Consume more escaped new lines
        while (chars.head().isNewLineChar()) {
            chars.advance();
        }
        return true;
    }
    return false;
}

private void completeBlockComment(DCharReader chars) {
    // Count and consume leading # symbols
    auto leading = 2;
    while (chars.head() == '#') {
        leading++;
        chars.advance();
    }
    // Consume print and white space characters
    // and look for a matching count of consecutive #
    auto trailing = 0;
    while (trailing < leading) {
        if (chars.head() == '#') {
            trailing++;
        } else if (chars.head().isPrintChar() || chars.head().isWhiteSpace()) {
            trailing = 0;
        } else {
            throw new SourceException("Unexpected character", chars.head(), chars.count);
        }
        chars.advance();
    }
}

private void completeLineComment(DCharReader chars) {
    while (chars.head().isPrintChar() || chars.head().isLineWhiteSpace()) {
        chars.advance();
    }
}

private void consumeNewLine(DCharReader chars) {
    if (chars.head() == '\r') {
        // CR
        chars.advance();
        if (chars.head() == '\n') {
            // CR LF
            chars.advance();
        }
    } else if (chars.head() == '\n') {
        // LF
        chars.advance();
    }
}

private dstring collectIndentation(DCharReader chars) {
    while (chars.head().isLineWhiteSpace()) {
        chars.collect();
    }
    return chars.popCollected();
}

private dstring collectSymbol(DCharReader chars) {
    while ((chars.peekCollected() ~ chars.head()).isSymbolPrefix()) {
        chars.collect();
    }
    return chars.popCollected();
}

private dstring collectStringLiteral(DCharReader chars) {
    // Opening "
    if (chars.head() != '"') {
        throw new SourceException("Expected opening \"", chars.head(), chars.count);
    }
    chars.collect();
    // String contents
    while (true) {
        if (chars.head().isPrintChar() && chars.head() != '"' && chars.head() != '\\') {
            chars.collect();
        } else if (chars.head().isLineWhiteSpace()) {
            chars.collect();
        } else if (chars.collectEscapeSequence()) {
            // Nothing to do, it is already collected by the "if" call
        } else {
            // Not part of a string literal body, end here
            break;
        }
    }
    // Closing "
    if (chars.head() != '"') {
        throw new SourceException("Expected closing \"", chars.head(), chars.count);
    }
    chars.collect();
    return chars.popCollected();
}

private dstring collectCharacterLiteral(DCharReader chars) {
    // Opening '
    if (chars.head() != '\'') {
        throw new SourceException("Expected opening \'", chars.head(), chars.count);
    }
    chars.collect();
    // Character contents
    if (chars.head().isPrintChar() && chars.head() != '\'' && chars.head() != '\\') {
        chars.collect();
    } else if (chars.head().isLineWhiteSpace()) {
        chars.collect();
    } else if (chars.collectEscapeSequence()) {
        // Nothing to do, it is already collected by the "if" call
    } else {
        throw new SourceException("CharacterLiteral has an empty body", chars.head(), chars.count);
    }
    // Closing '
    if (chars.head() != '\'') {
        throw new SourceException("Expected closing \'", chars.head(), chars.count);
    }
    chars.collect();
    return chars.popCollected();
}

private bool collectEscapeSequence(DCharReader chars) {
    if (chars.head() != '\\') {
        return false;
    }
    chars.collect();
    if (chars.head() == 'u') {
        chars.collect();
        // Unicode sequence, collect at least 1 hex digit and at most 8
        if (!chars.head().isHexDigit()) {
            throw new SourceException("Expected at least one hexadecimal digit in Unicode sequence",
                chars.head(), chars.count);
        }
        chars.collect();
        for (size_t i = 1; i < 8 && chars.head().isHexDigit(); i++) {
            chars.collect();
        }
        return true;
    }
    if (chars.head().isEscapeChar()) {
        chars.collect();
        return true;
    }
    return false;
}

private Token collectNumberLiteral(DCharReader chars) {
    auto position = chars.count;
    if (chars.head() == '0') {
        chars.collect();
        // Start with non-decimal integers
        if (chars.head() == 'b' || chars.head() == 'B') {
            // Binary integer
            chars.collect();
            chars.collectDigitSequence!isBinaryDigit();
            // Check if unsigned
            if (chars.head().isUnsignedSuffix()) {
                chars.collect();
                return new UnsignedIntegerLiteral(chars.popCollected(), position);
            }
            return new SignedIntegerLiteral(chars.popCollected(), position);
        }
        if (chars.head() == 'x' || chars.head() == 'X') {
            // Hexadecimal integer
            chars.collect();
            chars.collectDigitSequence!isHexDigit();
            // Check if unsigned
            if (chars.head().isUnsignedSuffix()) {
                chars.collect();
                return new UnsignedIntegerLiteral(chars.popCollected(), position);
            }
            return new SignedIntegerLiteral(chars.popCollected(), position);
        }
        if (chars.head().isDecimalDigit()) {
            // Not just a zero, collect more digits
            chars.collectDigitSequence!isDecimalDigit();
        }
    } else {
        // The number must have a decimal digit sequence first
        chars.collectDigitSequence!isDecimalDigit();
    }
    // Now we can have a decimal separator here, making it a float
    if (chars.head() == '.') {
        chars.collect();
        // There can be more digits after the decimal separator
        if (chars.head().isDecimalDigit()) {
            chars.collectDigitSequence!isDecimalDigit();
        }
        // We can have an optional exponent
        chars.collectFloatLiteralExponent();
        return new FloatLiteral(chars.popCollected(), position);
    }
    // Or we can have an exponent marker, again making it a float
    if (chars.collectFloatLiteralExponent()) {
        return new FloatLiteral(chars.popCollected(), position);
    }
    // Else it's a decimal integer and there's nothing more to do, just check if unsigned
    if (chars.head().isUnsignedSuffix()) {
        chars.collect();
        return new UnsignedIntegerLiteral(chars.popCollected(), position);
    }
    return new SignedIntegerLiteral(chars.popCollected(), position);
}

private Token completeFloatLiteralStartingWithDecimalSeparator(DCharReader chars, size_t position) {
    // Must have a decimal digit sequence next after the decimal
    chars.collectDigitSequence!isDecimalDigit();
    // We can have an optional exponent
    chars.collectFloatLiteralExponent();
    return new FloatLiteral(chars.popCollected(), position);
}

private bool collectFloatLiteralExponent(DCharReader chars) {
    // Only collect the exponent if it exists
    if (chars.head() != 'e' && chars.head() != 'E') {
        return false;
    }
    chars.collect();
    // It's an optional sign
    if (chars.head() == '-' || chars.head() == '+') {
        chars.collect();
    }
    // Followed by a decimal digit sequence
    chars.collectDigitSequence!isDecimalDigit();
    return true;
}

private void collectDigitSequence(alias isDigit)(DCharReader chars) {
    if (!isDigit(chars.head())) {
        throw new SourceException("Expected a digit", chars.head(), chars.count);
    }
    chars.collect();
    while (true) {
        if (chars.head() == '_') {
            chars.collect();
            while (chars.head() == '_') {
                chars.collect();
            }
            if (!isDigit(chars.head())) {
                throw new SourceException("Expected a digit", chars.head(), chars.count);
            }
            chars.collect();
        } else if (isDigit(chars.head())) {
            chars.collect();
        } else {
            break;
        }
    }
}

public immutable dstring[] SYMBOLS = [
   "!"d, "@"d, "%"d, "?"d, "&"d, "*"d, "("d, ")"d, "-"d, "="d,
   "+"d, "/"d, "^"d, ":"d, "<"d, ">"d, "["d, "]"d, "{"d, "}"d,
   "."d, ","d, "~"d, "|"d, "<<"d, ">>"d, ">>>"d, "<="d, ">="d, "<:"d,
   ">:"d, "<<:"d, ">>:"d, "<:>"d, "!="d, "::"d, "!:"d, "&&"d, "^^"d,
   "||"d, "**="d, "*="d, "/="d, "%="d, "+="d,"-="d, "<<="d, ">>="d,
   ">>>="d, "&="d, "^="d, "|="d, "&&="d, "^^="d,"||="d, "~="d, "="d,
   "=="d, "==="d, "!=="d, ".."d
];

public immutable dstring[] KEYWORDS = [
    "when"d, "with"d, "then"d, "match"d, "if"d, "else"d, "for"d, "for_rev"d, "while"d,
    "do"d, "try"d, "catch"d, "finally"d, "let"d, "var"d, "class"d, "void"d, "break"d,
    "continue"d, "throw"d, "static"d, "import"d, "package"d, "new"d, "throws"d, "public"d,
    "return"d, "this"d, "super"d
];

private immutable dstring NULL_LITERAL = "null"d;

private immutable dstring FALSE_LITERAL = "false"d;
private immutable dstring TRUE_LITERAL = "true"d;

private bool isSymbolChar(dchar c) {
    return SYMBOLS.canFind!"a[0] == b"(c);
}

unittest {
    assert('<'.isSymbolChar());
    assert(!'#'.isSymbolChar());
}

private bool isSymbolPrefix(dstring source) {
    return SYMBOLS.canFind!"a.length >= b.length && a[0 .. b.length] == b"(source);
}

unittest {
    assert("<<".isSymbolPrefix());
    assert(!"<*".isSymbolPrefix());
    assert(!"<<<<".isSymbolPrefix());
}

private bool isKeyword(dstring source) {
    return KEYWORDS.canFind(source);
}

private bool isBooleanLiteral(dstring source) {
    return source == FALSE_LITERAL || source == TRUE_LITERAL;
}

private bool isUnsignedSuffix(dchar c) {
    return c == 'u' || c == 'U';
}
