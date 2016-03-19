module ruleslang.syntax.chars;

import std.conv;
import std.exception;
import std.format;
import std.uni;
import std.algorithm;

private immutable dchar[dchar] ESCAPE_CHARS;
private immutable dchar[dchar] CHAR_ESCAPES;

static this() {
    dchar[dchar] forward = [
        'a': '\a',
        'b': '\b',
        't': '\t',
        'n': '\n',
        'v': '\v',
        'f': '\f',
        'r': '\r',
        '"': '"',
        '\\': '\\'
    ];
    dchar[dchar] reverse;
    foreach (c; forward.keys) {
        reverse[forward[c]] = c;
    }
    forward.rehash;
    reverse.rehash;
    ESCAPE_CHARS = assumeUnique(forward);
    CHAR_ESCAPES = assumeUnique(reverse);
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

public dchar decodeUnicodeEscape(dstring cs, ref size_t position) {
    auto length = cs.length;
    if (length < 2 || cs[0] != 'u') {
        throw new Exception(format("Not a valid unicode escape: %s", cs));
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
    if (c !in ESCAPE_CHARS) {
        throw new Exception(format("Not a valid escape character: %s", escapeChar(c)));
    }
    return ESCAPE_CHARS[c];
}

public dstring escapeChar(dchar c) {
    if (c in CHAR_ESCAPES) {
        return "\\" ~ CHAR_ESCAPES[c].to!dstring;
    }
    if (c.isGraphical()) {
        return c.to!dstring;
    }
    if (c > 0xFFFF) {
        return format("\\u%08X"d, c);
    }
    return format("\\u%04X"d, c);}

public dstring escapeString(dstring source) {
    // MAP-REDUCE! WHERE DOING BIG DATA CLOUD STUFF RIGHT HERE
    return source.map!escapeChar.reduce!"a ~ b";
}
