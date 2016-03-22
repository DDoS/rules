module ruleslang.syntax.token;

import std.format;
import std.array;
import std.conv;

import ruleslang.syntax.dchars;
import ruleslang.syntax.ast.expression;
import ruleslang.syntax.ast.mapper;

public enum Kind {
    INDENTATION,
    TERMINATOR,
    IDENTIFIER,
    KEYWORD,
    LOGICAL_NOT_OPERATOR,
    EXPONENT_OPERATOR,
    MULTIPLY_OPERATOR,
    ADD_OPERATOR,
    SHIFT_OPERATOR,
    VALUE_COMPARE_OPERATOR,
    TYPE_COMPARE_OPERATOR,
    BITWISE_AND_OPERATOR,
    BITWISE_XOR_OPERATOR,
    BITWISE_OR_OPERATOR,
    LOGICAL_AND_OPERATOR,
    LOGICAL_XOR_OPERATOR,
    LOGICAL_OR_OPERATOR,
    CONCATENATE_OPERATOR,
    RANGE_OPERATOR,
    ASSIGNMENT_OPERATOR,
    OTHER_SYMBOL,
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
            return getSource() == source;
        }

        public override string toString() {
            return format("%s(%s)", getKind().toString(), getSource());
        }
    }
}

public alias LogicalNotOperator = SourceToken!(Kind.LOGICAL_NOT_OPERATOR);
public alias ExponentOperator = SourceToken!(Kind.EXPONENT_OPERATOR);
public alias Indentation = SourceToken!(Kind.INDENTATION);
public alias Identifier = SourceToken!(Kind.IDENTIFIER);
public alias Keyword = SourceToken!(Kind.KEYWORD);
public alias MultiplyOperator = SourceToken!(Kind.MULTIPLY_OPERATOR);
public alias AddOperator = SourceToken!(Kind.ADD_OPERATOR);
public alias ShiftOperator = SourceToken!(Kind.SHIFT_OPERATOR);
public alias ValueCompareOperator = SourceToken!(Kind.VALUE_COMPARE_OPERATOR);
public alias TypeCompareOperator = SourceToken!(Kind.TYPE_COMPARE_OPERATOR);
public alias BitwiseAndOperator = SourceToken!(Kind.BITWISE_AND_OPERATOR);
public alias BitwiseXorOperator = SourceToken!(Kind.BITWISE_XOR_OPERATOR);
public alias BitwiseOrOperator = SourceToken!(Kind.BITWISE_OR_OPERATOR);
public alias LogicalAndOperator = SourceToken!(Kind.LOGICAL_AND_OPERATOR);
public alias LogicalXorOperator = SourceToken!(Kind.LOGICAL_XOR_OPERATOR);
public alias LogicalOrOperator = SourceToken!(Kind.LOGICAL_OR_OPERATOR);
public alias ConcatenateOperator = SourceToken!(Kind.CONCATENATE_OPERATOR);
public alias RangOperator = SourceToken!(Kind.RANGE_OPERATOR);
public alias AssignmentOperator = SourceToken!(Kind.ASSIGNMENT_OPERATOR);
public alias OtherSymbol = SourceToken!(Kind.OTHER_SYMBOL);

public class BooleanLiteral : SourceToken!(Kind.BOOLEAN_LITERAL), Expression {
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

    public override Expression accept(ExpressionMapper mapper) {
        return mapper.mapBooleanLiteral(this);
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
                    throw new Exception("Not a boolean: " ~ getSource());
            }
            evaluated = true;
        }
        return value;
    }

    public override string toString() {
        return super.toString();
    }

    unittest {
        auto a = new BooleanLiteral("true");
        assert(a.getValue());
        auto b = new BooleanLiteral("false");
        assert(!b.getValue());
    }
}

public class StringLiteral : SourceToken!(Kind.STRING_LITERAL), Expression {
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

    public override Expression accept(ExpressionMapper mapper) {
        return mapper.mapStringLiteral(this);
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
            buffer.reserve(64);
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

    public override string toString() {
        return super.toString();
    }

    unittest {
        auto a = new StringLiteral("\"hello\\u0041\\nlol\""d);
        assert(a.getValue() == "helloA\nlol"d);
        auto b = new StringLiteral("te st\u0004he\ny"d, true);
        assert(b.getSource() == "\"te st\\u00000004he\\ny\"");
    }
}

public class IntegerLiteral : SourceToken!(Kind.INTEGER_LITERAL), Expression {
    private uint _radix = 10;
    private bool sign = false;
    private long value;
    private bool evaluated = false;

    public this(dstring source) {
        super(source);
        if (source.length > 2) {
            switch (source[1]) {
                case 'b':
                case 'B':
                    _radix = 2;
                    break;
                case 'x':
                case 'X':
                    _radix = 16;
                    break;
                default:
                    break;
            }
        }
    }

    public this(long value) {
        super(value.to!dstring);
        this.value = value;
        evaluated = true;
    }

    @property public uint radix() {
        return _radix;
    }

    public override Expression accept(ExpressionMapper mapper) {
        return mapper.mapIntegerLiteral(this);
    }

    public void negateSign() {
        if (_radix != 10) {
            throw new Exception("Cannot negate sign in source for non-decimal integers");
        }
        sign ^= true;
        evaluated = false;
    }

    public override string getSource() {
        if (sign) {
            return "-" ~ super.getSource();
        }
        return super.getSource();
    }

    public long getValue() {
        if (!evaluated) {
            auto source = getSource().replace("_", "");
            if (radix != 10) {
                source = source[2 .. $];
            }
            value = source.to!long(_radix);
            evaluated = true;
        }
        return value;
    }

    public override string toString() {
        return super.toString();
    }

    unittest {
        auto a = new IntegerLiteral("424_32");
        assert(a.getValue() == 42432);
        a.negateSign();
        assert(a.getValue() == -42432);
    	auto b = new IntegerLiteral("0xFFFF");
        assert(b.getValue() == 0xFFFF);
    	auto c = new IntegerLiteral("0b1110");
        assert(c.getValue() == 0b1110);
    }
}

public class FloatLiteral : SourceToken!(Kind.FLOAT_LITERAL), Expression {
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

    public override Expression accept(ExpressionMapper mapper) {
        return mapper.mapFloatLiteral(this);
    }

    public real getValue() {
        if (!evaluated) {
            value = getSource().to!real;
            evaluated = true;
        }
        return value;
    }

    public override string toString() {
        return super.toString();
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
        return Kind.EOF;
    }

    public override bool opEquals(const string source) {
        return "\u0004" == source;
    }

    public override string toString() {
        return "EOF()";
    }
}

public string toString(Kind kind) {
    final switch (kind) with (Kind) {
        case INDENTATION:
            return "Indentation";
        case TERMINATOR:
            return "Terminator";
        case IDENTIFIER:
            return "Identifier";
        case KEYWORD:
            return "Keyword";
        case LOGICAL_NOT_OPERATOR:
        case EXPONENT_OPERATOR:
        case MULTIPLY_OPERATOR:
        case ADD_OPERATOR:
        case SHIFT_OPERATOR:
        case VALUE_COMPARE_OPERATOR:
        case TYPE_COMPARE_OPERATOR:
        case BITWISE_AND_OPERATOR:
        case BITWISE_XOR_OPERATOR:
        case BITWISE_OR_OPERATOR:
        case LOGICAL_AND_OPERATOR:
        case LOGICAL_XOR_OPERATOR:
        case LOGICAL_OR_OPERATOR:
        case CONCATENATE_OPERATOR:
        case RANGE_OPERATOR:
        case ASSIGNMENT_OPERATOR:
        case OTHER_SYMBOL:
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
    }
}

public Token newSymbol(dstring source) {
    auto constructor = source in OPERATOR_SOURCES;
    if (constructor !is null) {
        return (*constructor)(source);
    }
    return new OtherSymbol(source);
}

private Token function(dstring)[dstring] OPERATOR_SOURCES;

private void addSourcesForOperator(Op)(dstring[] sources ...) {
    Token function(dstring) constructor = (dstring source) => new Op(source);
    foreach (source; sources) {
        if (source in OPERATOR_SOURCES) {
            throw new Exception("Symbol is declared for two different operators: " ~ source.to!string);
        }
        OPERATOR_SOURCES[source] = constructor;
    }
    OPERATOR_SOURCES.rehash;
}

private static this() {
    addSourcesForOperator!LogicalNotOperator("!"d);
    addSourcesForOperator!ExponentOperator("**"d);
    addSourcesForOperator!MultiplyOperator("*"d, "/"d, "%"d);
    addSourcesForOperator!AddOperator("+"d, "-"d);
    addSourcesForOperator!ShiftOperator("<<"d, ">>"d, ">>>"d);
    addSourcesForOperator!ValueCompareOperator("==="d, "!=="d, "=="d, "!="d, "<"d, ">"d, "<="d, ">="d);
    addSourcesForOperator!TypeCompareOperator("::"d, "!:"d, "<:"d, ">:"d, "<<:"d, ">>:"d, "<:>"d);
    addSourcesForOperator!BitwiseAndOperator("&"d);
    addSourcesForOperator!BitwiseXorOperator("^"d);
    addSourcesForOperator!BitwiseOrOperator("|"d);
    addSourcesForOperator!LogicalAndOperator("&&"d);
    addSourcesForOperator!LogicalXorOperator("^^"d);
    addSourcesForOperator!LogicalOrOperator("||"d);
    addSourcesForOperator!ConcatenateOperator("~"d);
    addSourcesForOperator!RangOperator(".."d);
    addSourcesForOperator!AssignmentOperator(
        "**="d, "*="d, "/="d, "%="d, "+="d, "-="d, "<<="d, ">>="d,
        ">>>="d, "&="d, "^="d, "|="d, "&&="d, "^^="d, "||="d, "~="d, "="d
    );
}
