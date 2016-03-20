module ruleslang.syntax.token;

import std.format;
import std.array;
import std.conv;

import ruleslang.syntax.chars;

public enum Kind {
    INDENTATION,
    TERMINATOR,
    IDENTIFIER,
    KEYWORD,
    MULTIPLY_OPERATOR,
    ADD_OPERATOR,
    SHIFT_OPERATOR,
    VALUE_COMPARE_OPERATOR,
    TYPE_COMPARE_OPERATOR,
    ASSIGNMENT_OPERATOR,
    UNIQUE_SYMBOL,
    BOOLEAN_LITERAL,
    STRING_LITERAL,
    INTEGER_LITERAL,
    FLOAT_LITERAL,
    EOF
}

public interface Token {
    public string getSource();
    public Kind getKind();
    public bool opEquals(const string source);
    public string toString();
}

public class Terminator : Token {
    public override string getSource() {
        return ";";
    }

    public Kind getKind() {
        return Kind.TERMINATOR;
    }

    public override bool opEquals(const string source) {
        return ";" == source;
    }

    public override string toString() {
        return "Terminator(;)";
    }
}

public template SourceToken(Kind kind) {
    public class SourceToken : Token {
        private string source;

        public this(dstring source) {
            this.source = source.to!string;
        }

        public override string getSource() {
            return source;
        }

        public override Kind getKind() {
            return kind;
        }

        public override bool opEquals(const string source) {
            return this.source == source;
        }

        public override string toString() {
            return format("%s(%s)", getKind().toString(), source);
        }
    }
}

public alias Indentation = SourceToken!(Kind.INDENTATION);
public alias Keyword = SourceToken!(Kind.KEYWORD);
public alias MultiplyOperator = SourceToken!(Kind.MULTIPLY_OPERATOR);
public alias AddOperator = SourceToken!(Kind.ADD_OPERATOR);
public alias ShiftOperator = SourceToken!(Kind.SHIFT_OPERATOR);
public alias ValueCompareOperator = SourceToken!(Kind.VALUE_COMPARE_OPERATOR);
public alias TypeCompareOperator = SourceToken!(Kind.TYPE_COMPARE_OPERATOR);
public alias AssignmentOperator = SourceToken!(Kind.ASSIGNMENT_OPERATOR);
public alias UniqueSymbol = SourceToken!(Kind.UNIQUE_SYMBOL);

public class BooleanLiteral : SourceToken!(Kind.BOOLEAN_LITERAL) {
    private bool value;
    private bool evaluated = false;

    public this(dstring source) {
        super(source);
    }

    public this(bool value) {
        super(value.to!dstring);
        this.value = value;
        evaluated = true;
    }

    public bool getValue() {
        if (!evaluated) {
            switch (getSource()) {
                case "true":
                    value = true;
                    break;
                case "false":
                    value = false;
                    break;
                default:
                    throw new Exception("Not a boolean: " ~ source);
            }
            evaluated = true;
        }
        return value;
    }

    unittest {
        auto a = new BooleanLiteral("true");
        assert(a.getValue());
        auto b = new BooleanLiteral("false");
        assert(!b.getValue());
    }
}

public class StringLiteral : SourceToken!(Kind.STRING_LITERAL) {
    private dstring original;
    private dstring value = null;

    public this(dstring source) {
        this(source, false);
    }

    public this(dstring s, bool value) {
        if (value) {
            auto source = '"' ~ escapeString(s) ~ '"';
            super(source);
            this.value = s;
        } else {
            super(s);
        }
        this.original = s;
    }

    public dstring getValue() {
        if (value is null) {
            auto length = original.length;
            if (length < 2) {
                throw new Exception("String is missing enclosing quotes");
            }
            if (original[0] != '"') {
                throw new Exception("String is missing beginning quote");
            }
            dchar[] buffer = [];
            for (size_t i = 1; i < length - 1; ) {
                dchar c = original[i];
                i += 1;
                if (c == '\\') {
                    c = original[i];
                    i += 1;
                    if (c == 'u') {
                        c = original[i - 1 .. $].decodeUnicodeEscape(i);
                    } else {
                        c = c.decodeCharEscape();
                    }
                }
                buffer ~= c;
            }
            if (original[length - 1] != '"') {
                throw new Exception("String is missing ending quote");
            }
            value = buffer.idup;
        }
        return value;
    }

    unittest {
        auto a = new StringLiteral("\"hello\\u0041\\nlol\""d);
        assert(a.getValue() == "helloA\nlol"d);
        auto b = new StringLiteral("te st\u0004he\ny"d, true);
        assert(b.getSource() == "\"te st\\u0004he\\ny\"");
    }
}

public class IntegerLiteral : SourceToken!(Kind.INTEGER_LITERAL) {
    private long value;
    private bool evaluated = false;

    public this(dstring source) {
        super(source);
    }

    public this(long value) {
        super(value.to!dstring);
        this.value = value;
        evaluated = true;
    }

    public long getValue() {
        if (!evaluated) {
            auto source = getSource().replace("_", "");
            uint radix = 10;
            if (source.length > 2) {
                switch (source[1]) {
                    case 'b':
                    case 'B':
                        radix = 2;
                        source = source[2 .. $];
                        break;
                    case 'x':
                    case 'X':
                        radix = 16;
                        source = source[2 .. $];
                        break;
                    default:
                        break;
                }
            }
            value = source.parse!long(radix);
            evaluated = true;
        }
        return value;
    }

    unittest {
        auto a = new IntegerLiteral("424_32");
        assert(a.getValue() == 42432);
    	auto b = new IntegerLiteral("0xFFFF");
        assert(b.getValue() == 0xFFFF);
    	auto c = new IntegerLiteral("0b1110");
        assert(c.getValue() == 0b1110);
    }
}

public class FloatLiteral : SourceToken!(Kind.FLOAT_LITERAL) {
    private real value;
    private bool evaluated = false;

    public this(dstring source) {
        super(source);
    }

    public this(real value) {
        super(value.to!dstring);
        this.value = value;
        evaluated = true;
    }

    public real getValue() {
        if (!evaluated) {
            value = getSource().to!real;
            evaluated = true;
        }
        return value;
    }

    unittest {
        auto a = new FloatLiteral("1_10e12");
        assert(a.getValue() == 1_10e12);
    	auto b = new FloatLiteral("1.1");
        assert(b.getValue() == 1.1);
    	auto c = new FloatLiteral(".1");
        assert(c.getValue() == 0.1);
    }
}

public class Eof : Token {
    public override string getSource() {
        return "\u0004";
    }

    public Kind getKind() {
        return Kind.TERMINATOR;
    }

    public override bool opEquals(const string source) {
        return "\u0004" == source;
    }

    public override string toString() {
        return "EOF()";
    }
}

public string toString(Kind kind) {
    switch (kind) with (Kind) {
        case INDENTATION:
            return "Indentation";
        case TERMINATOR:
            return "Terminator";
        case IDENTIFIER:
            return "Identifier";
        case KEYWORD:
            return "Keyword";
        case MULTIPLY_OPERATOR:
        case ADD_OPERATOR:
        case SHIFT_OPERATOR:
        case VALUE_COMPARE_OPERATOR:
        case TYPE_COMPARE_OPERATOR:
        case ASSIGNMENT_OPERATOR:
        case UNIQUE_SYMBOL:
            return "Symbol";
        case BOOLEAN_LITERAL:
            return "BooleanLiteral";
        case STRING_LITERAL:
            return "StringLiteral";
        case INTEGER_LITERAL:
            return "IntegerLiteral";
        case FLOAT_LITERAL:
            return "FloatLiteral";
        case EOF:
            return "EOF";
        default:
            throw new Exception(format("Unknown kind: %s", kind));
    }
}

public Token newSymbol(dstring source) {
    if (source !in OPERATOR_SOURCES) {
        return OPERATOR_SOURCES[source](source);
    }
    return new UniqueSymbol(source);
}

private Token function(dstring)[dstring] OPERATOR_SOURCES;

private void addSourcesForOperator(Op)(dstring[] sources ...) {
    Token function(dstring) constructor = (dstring source) => new Op(source);
    foreach (source; sources) {
        OPERATOR_SOURCES[source] = constructor;
    }
    OPERATOR_SOURCES.rehash;
}

private static this() {
    addSourcesForOperator!MultiplyOperator("*"d, "/"d, "%"d);
    addSourcesForOperator!AddOperator("+"d, "-"d);
    addSourcesForOperator!ShiftOperator("<<"d, ">>"d, ">>>"d);
    addSourcesForOperator!ValueCompareOperator("==="d, "!=="d, "=="d, "!="d, "<"d, ">"d, "<="d, ">="d);
    addSourcesForOperator!TypeCompareOperator("::"d, "!:"d, "<:"d, ">:"d, "<<:"d, ">>:"d, "<:>"d);
    addSourcesForOperator!AssignmentOperator(
        "**="d, "*="d, "/="d, "%="d, "+="d, "-="d, "<<="d, ">>="d,
        ">>>="d, "&="d, "^="d, "|="d, "&&="d, "^^="d, "||="d, "~="d, "="d
    );
}
