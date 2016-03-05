package lang

import "fmt"

type Kind uint

const (
    INDENTATION Kind = iota
    TERMINATOR
    IDENTIFIER
    KEYWORD
    MULTIPLY_OPERATOR
    ADD_OPERATOR
    SHIFT_OPERATOR
    COMPARE_OPERATOR
    LOGICAL_AND_OPERATOR
    LOGICAL_XOR_OPERATOR
    LOGICAL_OR_OPERATOR
    ASSIGNMENT_OPERATOR
    OTHER_SYMBOL
    BOOLEAN_LITERAL
    STRING_LITERAL
    BINARY_INTEGER_LITERAL
    DECIMAL_INTEGER_LITERAL
    HEXADECIMAL_INTEGER_LITERAL
    FLOAT_LITERAL
    EOF
)

type Token struct {
    Source string
    Kind Kind
}

func Indentation(source []rune) *Token {
    return &Token{string(source), INDENTATION}
}

var TerminatorToken *Token = &Token{";", TERMINATOR}

func Identifier(source []rune) *Token {
    return &Token{string(source), IDENTIFIER}
}

func Keyword(source []rune) *Token {
    return &Token{string(source), KEYWORD}
}

func Symbol(source []rune) *Token {
    stringSource := string(source)
    return &Token{stringSource, getSymbolType(stringSource)}
}

func BooleanLiteral(source []rune) *Token {
    return &Token{string(source), BOOLEAN_LITERAL}
}

func StringLiteral(source []rune) *Token {
    return &Token{string(source), STRING_LITERAL}
}

func BinaryIntegerLiteral(source []rune) *Token {
    return &Token{string(source), BINARY_INTEGER_LITERAL}
}

func DecimalIntegerLiteral(source []rune) *Token {
    return &Token{string(source), DECIMAL_INTEGER_LITERAL}
}

func HexadecimalIntegerLiteral(source []rune) *Token {
    return &Token{string(source), HEXADECIMAL_INTEGER_LITERAL}
}

func FloatLiteral(source []rune) *Token {
    return &Token{string(source), FLOAT_LITERAL}
}

var EofToken *Token = &Token{"\u0004", EOF}

func (token *Token) Is(source string) bool {
    return token.Source == source
}

func (token *Token) Any(source ...string) bool {
    for _, s := range source {
        if token.Is(s) {
            return true
        }
    }
    return false
}

func (token *Token) String() string {
    return fmt.Sprintf("%s(%s)", token.Kind.String(), token.Source)
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
    case MULTIPLY_OPERATOR:
        fallthrough
    case ADD_OPERATOR:
        fallthrough
    case SHIFT_OPERATOR:
        fallthrough
    case COMPARE_OPERATOR:
        fallthrough
    case LOGICAL_AND_OPERATOR:
        fallthrough
    case LOGICAL_XOR_OPERATOR:
        fallthrough
    case LOGICAL_OR_OPERATOR:
        fallthrough
    case ASSIGNMENT_OPERATOR:
        fallthrough
    case OTHER_SYMBOL:
        return "Symbol"
    case BOOLEAN_LITERAL:
        return "BooleanLiteral"
    case STRING_LITERAL:
        return "StringLiteral"
    case BINARY_INTEGER_LITERAL:
        return "BinaryIntegerLiteral"
    case DECIMAL_INTEGER_LITERAL:
        return "DecimalIntegerLiteral"
    case HEXADECIMAL_INTEGER_LITERAL:
        return "HexadecimalIntegerLiteral"
    case FLOAT_LITERAL:
        return "FloatLiteral"
    case EOF:
        return "EOF"
    }
    panic(fmt.Sprintf("Unknown token kind %d", kind))
}

func (kind Kind) IsLiteral() bool {
    switch kind {
    case BOOLEAN_LITERAL:
        fallthrough
    case STRING_LITERAL:
        fallthrough
    case BINARY_INTEGER_LITERAL:
        fallthrough
    case DECIMAL_INTEGER_LITERAL:
        fallthrough
    case HEXADECIMAL_INTEGER_LITERAL:
        fallthrough
    case FLOAT_LITERAL:
        return true
    default:
        return false
    }
}

func getSymbolType(symbol string) Kind {
    operator, has := OPERATOR_TYPES[string(symbol)]
    if has {
        return operator
    }
    return OTHER_SYMBOL
}

var OPERATOR_TYPES = map[string]Kind{
    "*": MULTIPLY_OPERATOR, "/": MULTIPLY_OPERATOR, "%": MULTIPLY_OPERATOR,
    "+": ADD_OPERATOR, "-": ADD_OPERATOR,
    "<<": SHIFT_OPERATOR, ">>": SHIFT_OPERATOR, ">>>": SHIFT_OPERATOR,
    "==": COMPARE_OPERATOR, "<": COMPARE_OPERATOR, ">": COMPARE_OPERATOR, "<=": COMPARE_OPERATOR, ">=": COMPARE_OPERATOR,
    "::": COMPARE_OPERATOR, "<:": COMPARE_OPERATOR, ">:": COMPARE_OPERATOR, "<<:": COMPARE_OPERATOR, ">>:": COMPARE_OPERATOR,
    "<:>": COMPARE_OPERATOR, "!=": COMPARE_OPERATOR, "===": COMPARE_OPERATOR, "!==": COMPARE_OPERATOR,
    "&&": LOGICAL_AND_OPERATOR,
    "^^": LOGICAL_XOR_OPERATOR,
    "||": LOGICAL_OR_OPERATOR,
    "**=": ASSIGNMENT_OPERATOR, "*=": ASSIGNMENT_OPERATOR, "/=": ASSIGNMENT_OPERATOR, "%=": ASSIGNMENT_OPERATOR,
    "+=": ASSIGNMENT_OPERATOR, "-=": ASSIGNMENT_OPERATOR, "<<=": ASSIGNMENT_OPERATOR, ">>=": ASSIGNMENT_OPERATOR,
    ">>>=": ASSIGNMENT_OPERATOR, "&=": ASSIGNMENT_OPERATOR, "^=": ASSIGNMENT_OPERATOR, "|=": ASSIGNMENT_OPERATOR,
    "&&=": ASSIGNMENT_OPERATOR, "^^=": ASSIGNMENT_OPERATOR, "||=": ASSIGNMENT_OPERATOR, "~=": ASSIGNMENT_OPERATOR,
    "=": ASSIGNMENT_OPERATOR,
}

var PRIMITIVE_TYPES = []string{"bool", "byte", "short", "int", "long", "half", "float", "double"}
