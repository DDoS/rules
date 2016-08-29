module ruleslang.syntax.dchars;

import std.conv : parse, to;
import std.exception : assumeUnique;
import std.format : format;
import std.uni : isGraphical;
import std.algorithm.iteration : map, fold;

import ruleslang.util;

private immutable dchar[dchar] ESCAPE_CHARS;
private immutable dchar[dchar] CHAR_ESCAPES;

public static this() {
    dchar[dchar] forward = [
        'a': '\a',
        'b': '\b',
        't': '\t',
        'n': '\n',
        'v': '\v',
        'f': '\f',
        'r': '\r',
        '"': '"',
        '\'': '\'',
        '\\': '\\'
    ];
    dchar[dchar] reverse = forward.inverse();
    forward.rehash;
    reverse.rehash;
    ESCAPE_CHARS = assumeUnique(forward);
    CHAR_ESCAPES = assumeUnique(reverse);
}

public bool isIdentifierStart(dchar c) {
    return c == '_' || isLetter(c);
}

public bool isIdentifierBody(dchar c) {
    return isIdentifierStart(c) || isDecimalDigit(c);
}

public bool isLetter(dchar c) {
    return c >= 'A' && c <= 'Z' || c >= 'a' && c <= 'z';
}

public bool isBinaryDigit(dchar c) {
    return c == '0' || c == '1';
}

public bool isDecimalDigit(dchar c) {
    return isBinaryDigit(c) || c >= '2' && c <= '9';
}

public bool isHexDigit(dchar c) {
    return isDecimalDigit(c) || c >= 'A' && c <= 'F' || c >= 'a' && c <= 'f';
}

public bool isPrintChar(dchar c) {
    return c >= '!' && c <= '~';
}

public bool isNewLineChar(dchar c) {
    return c == '\n' || c == '\r';
}

public bool isLineWhiteSpace(dchar c) {
    return c == ' ' || c == '\t';
}

public bool isWhiteSpace(dchar c) {
    return isNewLineChar(c) || isLineWhiteSpace(c);
}

public bool isEscapeChar(dchar c) {
    return (c in ESCAPE_CHARS) !is null;
}

public dchar decodeUnicodeEscape(dstring cs, ref size_t position) {
    auto length = cs.length;
    if (length < 2 || cs[0] != 'u') {
        throw new Error(format("Not a valid unicode escape: %s", cs));
    }
    size_t i = 1;
    while (i < length && i < 9 && cs[i].isHexDigit()) {
        i += 1;
    }
    dstring unicodeSequence = cs[1 .. i];
    dchar val = unicodeSequence.parse!uint(16u);
    position += i - 1;
    return val;
}

public dchar decodeCharEscape(dchar c) {
    auto char_ = c in ESCAPE_CHARS;
    if (char_ is null) {
        throw new Error(format("Not a valid escape character: %s", escapeChar(c)));
    }
    return *char_;
}

public dstring escapeChar(dchar c) {
    auto escape = c in CHAR_ESCAPES;
    if (escape !is null) {
        return "\\" ~ (*escape).to!dstring;
    }
    if (c.isGraphical()) {
        return c.to!dstring;
    }
    return format("\\u%08X"d, c).to!dstring;
}

public dstring escapeString(dstring source) {
    return source.map!escapeChar.fold!"a ~ b"(""d);
}
