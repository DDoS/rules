package syntax

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
    VALUE_COMPARE_OPERATOR
    TYPE_COMPARE_OPERATOR
    LOGICAL_AND_OPERATOR
    LOGICAL_XOR_OPERATOR
    LOGICAL_OR_OPERATOR
    RANGE_OPERATOR
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

type Token interface {
    Source() string
    Is(string) bool
    Kind() Kind
    String() string
}

type SourceToken struct {
    source string
}

type IndentationToken struct {
    SourceToken
}

type TerminatorToken struct {
}

type IdentifierToken struct {
    SourceToken
}

type KeywordToken struct {
    SourceToken
}

type SymbolToken struct {
    SourceToken
    kind Kind
}

type BooleanLiteralToken struct {
    SourceToken
}

type StringLiteralToken struct {
    SourceToken
}

type BinaryIntegerLiteralToken struct {
    SourceToken
}

type DecimalIntegerLiteralToken struct {
    SourceToken
}

type HexadecimalIntegerLiteralToken struct {
    SourceToken
}

type FloatLiteralToken struct {
    SourceToken
}

type EofToken struct {
}

func Indentation(source []rune) *IndentationToken {
    return &IndentationToken{SourceToken{string(source)}}
}

var terminatorToken *TerminatorToken = &TerminatorToken{}

func Terminator() *TerminatorToken {
    return terminatorToken
}

func Identifier(source []rune) *IdentifierToken {
    return &IdentifierToken{SourceToken{string(source)}}
}

func Keyword(source []rune) *KeywordToken {
    return &KeywordToken{SourceToken{string(source)}}
}

func Symbol(source []rune) *SymbolToken {
    stringSource := string(source)
    return &SymbolToken{SourceToken{stringSource}, getSymbolType(stringSource)}
}

func BooleanLiteral(source []rune) *BooleanLiteralToken {
    return &BooleanLiteralToken{SourceToken{string(source)}}
}

func StringLiteral(source []rune) *StringLiteralToken {
    return &StringLiteralToken{SourceToken{string(source)}}
}

func BinaryIntegerLiteral(source []rune) *BinaryIntegerLiteralToken {
    return &BinaryIntegerLiteralToken{SourceToken{string(source)}}
}

func DecimalIntegerLiteral(source []rune) *DecimalIntegerLiteralToken {
    return &DecimalIntegerLiteralToken{SourceToken{string(source)}}
}

func HexadecimalIntegerLiteral(source []rune) *HexadecimalIntegerLiteralToken {
    return &HexadecimalIntegerLiteralToken{SourceToken{string(source)}}
}

func FloatLiteral(source []rune) *FloatLiteralToken {
    return &FloatLiteralToken{SourceToken{string(source)}}
}

var eofToken *EofToken = &EofToken{}

func Eof() *EofToken {
    return eofToken
}

func (this *SourceToken) Source() string {
    return this.source
}

func (this *TerminatorToken) Source() string {
    return ";"
}

func (this *EofToken) Source() string {
    return "\u0004"
}

func (this *SourceToken) Is(source string) bool {
    return this.Source() == source
}

func (this *TerminatorToken) Is(source string) bool {
    return ";" == source
}

func (this *EofToken) Is(source string) bool {
    return "\u0004" == source
}

func (this *IndentationToken) Kind() Kind {
    return INDENTATION
}

func (this *TerminatorToken) Kind() Kind {
    return TERMINATOR
}

func (this *IdentifierToken) Kind() Kind {
    return IDENTIFIER
}

func (this *KeywordToken) Kind() Kind {
    return KEYWORD
}

func (this *SymbolToken) Kind() Kind {
    return this.kind
}

func (this *BooleanLiteralToken) Kind() Kind {
    return BOOLEAN_LITERAL
}

func (this *StringLiteralToken) Kind() Kind {
    return STRING_LITERAL
}

func (this *BinaryIntegerLiteralToken) Kind() Kind {
    return BINARY_INTEGER_LITERAL
}

func (this *DecimalIntegerLiteralToken) Kind() Kind {
    return DECIMAL_INTEGER_LITERAL
}

func (this *HexadecimalIntegerLiteralToken) Kind() Kind {
    return HEXADECIMAL_INTEGER_LITERAL
}

func (this *FloatLiteralToken) Kind() Kind {
    return FLOAT_LITERAL
}

func (this *EofToken) Kind() Kind {
    return EOF
}

func (this *IndentationToken) String() string {
    return fmt.Sprintf("Indentation(%s)", this.source)
}

func (this *TerminatorToken) String() string {
    return "Terminator(;)"
}

func (this *IdentifierToken) String() string {
    return fmt.Sprintf("Identifier(%s)", this.source)
}

func (this *KeywordToken) String() string {
    return fmt.Sprintf("Keyword(%s)", this.source)
}

func (this *SymbolToken) String() string {
    return fmt.Sprintf("Symbol(%s)", this.source)
}

func (this *BooleanLiteralToken) String() string {
    return fmt.Sprintf("BooleanLiteral(%s)", this.source)
}

func (this *StringLiteralToken) String() string {
    return fmt.Sprintf("StringLiteral(%s)", this.source)
}

func (this *BinaryIntegerLiteralToken) String() string {
    return fmt.Sprintf("BinaryIntegerLiteral(%s)", this.source)
}

func (this *DecimalIntegerLiteralToken) String() string {
    return fmt.Sprintf("DecimalIntegerLiteral(%s)", this.source)
}

func (this *HexadecimalIntegerLiteralToken) String() string {
    return fmt.Sprintf("HexadecimalIntegerLiteral(%s)", this.source)
}

func (this *FloatLiteralToken) String() string {
    return fmt.Sprintf("FloatLiteral(%s)", this.source)
}

func (this *EofToken) String() string {
    return "EOF()"
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
    "===": VALUE_COMPARE_OPERATOR, "!==": VALUE_COMPARE_OPERATOR, "==": VALUE_COMPARE_OPERATOR,
    "!=": VALUE_COMPARE_OPERATOR, "<": VALUE_COMPARE_OPERATOR, ">": VALUE_COMPARE_OPERATOR,
    "<=": VALUE_COMPARE_OPERATOR, ">=": VALUE_COMPARE_OPERATOR,
    "::": TYPE_COMPARE_OPERATOR, "!:": TYPE_COMPARE_OPERATOR, "<:": TYPE_COMPARE_OPERATOR, ">:": TYPE_COMPARE_OPERATOR,
    "<<:": TYPE_COMPARE_OPERATOR, ">>:": TYPE_COMPARE_OPERATOR, "<:>": TYPE_COMPARE_OPERATOR,
    "&&": LOGICAL_AND_OPERATOR,
    "^^": LOGICAL_XOR_OPERATOR,
    "||": LOGICAL_OR_OPERATOR,
    "..": RANGE_OPERATOR,
    "**=": ASSIGNMENT_OPERATOR, "*=": ASSIGNMENT_OPERATOR, "/=": ASSIGNMENT_OPERATOR, "%=": ASSIGNMENT_OPERATOR,
    "+=": ASSIGNMENT_OPERATOR, "-=": ASSIGNMENT_OPERATOR, "<<=": ASSIGNMENT_OPERATOR, ">>=": ASSIGNMENT_OPERATOR,
    ">>>=": ASSIGNMENT_OPERATOR, "&=": ASSIGNMENT_OPERATOR, "^=": ASSIGNMENT_OPERATOR, "|=": ASSIGNMENT_OPERATOR,
    "&&=": ASSIGNMENT_OPERATOR, "^^=": ASSIGNMENT_OPERATOR, "||=": ASSIGNMENT_OPERATOR, "~=": ASSIGNMENT_OPERATOR,
    "=": ASSIGNMENT_OPERATOR,
}

var PRIMITIVE_TYPES = []string{"bool", "byte", "short", "int", "long", "half", "float", "double"}
