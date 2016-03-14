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

type Source_ struct {
    source string
}

type Indentation struct {
    Source_
}

type Terminator struct {
}

type Identifier struct {
    Source_
}

type Keyword struct {
    Source_
}

type Symbol struct {
    Source_
    kind Kind
}

type BooleanLiteral struct {
    Source_
}

type StringLiteral struct {
    Source_
}

type BinaryIntegerLiteral struct {
    Source_
}

type DecimalIntegerLiteral struct {
    Source_
}

type HexadecimalIntegerLiteral struct {
    Source_
}

type FloatLiteral struct {
    Source_
}

type Eof struct {
}

func NewIndentation(source []rune) *Indentation {
    return &Indentation{Source_{string(source)}}
}

var terminator *Terminator = &Terminator{}

func NewTerminator() *Terminator {
    return terminator
}

func NewIdentifier(source []rune) *Identifier {
    return &Identifier{Source_{string(source)}}
}

func NewKeyword(source []rune) *Keyword {
    return &Keyword{Source_{string(source)}}
}

func NewSymbol(source []rune) *Symbol {
    stringSource := string(source)
    return &Symbol{Source_{stringSource}, getSymbolType(stringSource)}
}

func NewBooleanLiteral(source []rune) *BooleanLiteral {
    return &BooleanLiteral{Source_{string(source)}}
}

func NewStringLiteral(source []rune) *StringLiteral {
    return &StringLiteral{Source_{string(source)}}
}

func NewBinaryIntegerLiteral(source []rune) *BinaryIntegerLiteral {
    return &BinaryIntegerLiteral{Source_{string(source)}}
}

func NewDecimalIntegerLiteral(source []rune) *DecimalIntegerLiteral {
    return &DecimalIntegerLiteral{Source_{string(source)}}
}

func NewHexadecimalIntegerLiteral(source []rune) *HexadecimalIntegerLiteral {
    return &HexadecimalIntegerLiteral{Source_{string(source)}}
}

func NewFloatLiteral(source []rune) *FloatLiteral {
    return &FloatLiteral{Source_{string(source)}}
}

var eof *Eof = &Eof{}

func NewEof() *Eof {
    return eof
}

func (this *Source_) Source() string {
    return this.source
}

func (this *Terminator) Source() string {
    return ";"
}

func (this *Eof) Source() string {
    return "\u0004"
}

func (this *Source_) Is(source string) bool {
    return this.Source() == source
}

func (this *Terminator) Is(source string) bool {
    return ";" == source
}

func (this *Eof) Is(source string) bool {
    return "\u0004" == source
}

func (this *Indentation) Kind() Kind {
    return INDENTATION
}

func (this *Terminator) Kind() Kind {
    return TERMINATOR
}

func (this *Identifier) Kind() Kind {
    return IDENTIFIER
}

func (this *Keyword) Kind() Kind {
    return KEYWORD
}

func (this *Symbol) Kind() Kind {
    return this.kind
}

func (this *BooleanLiteral) Kind() Kind {
    return BOOLEAN_LITERAL
}

func (this *StringLiteral) Kind() Kind {
    return STRING_LITERAL
}

func (this *BinaryIntegerLiteral) Kind() Kind {
    return BINARY_INTEGER_LITERAL
}

func (this *DecimalIntegerLiteral) Kind() Kind {
    return DECIMAL_INTEGER_LITERAL
}

func (this *HexadecimalIntegerLiteral) Kind() Kind {
    return HEXADECIMAL_INTEGER_LITERAL
}

func (this *FloatLiteral) Kind() Kind {
    return FLOAT_LITERAL
}

func (this *Eof) Kind() Kind {
    return EOF
}

func (this *Indentation) String() string {
    return fmt.Sprintf("Indentation(%s)", this.source)
}

func (this *Terminator) String() string {
    return "Terminator(;)"
}

func (this *Identifier) String() string {
    return fmt.Sprintf("Identifier(%s)", this.source)
}

func (this *Keyword) String() string {
    return fmt.Sprintf("Keyword(%s)", this.source)
}

func (this *Symbol) String() string {
    return fmt.Sprintf("Symbol(%s)", this.source)
}

func (this *BooleanLiteral) String() string {
    return fmt.Sprintf("BooleanLiteral(%s)", this.source)
}

func (this *StringLiteral) String() string {
    return fmt.Sprintf("StringLiteral(%s)", this.source)
}

func (this *BinaryIntegerLiteral) String() string {
    return fmt.Sprintf("BinaryIntegerLiteral(%s)", this.source)
}

func (this *DecimalIntegerLiteral) String() string {
    return fmt.Sprintf("DecimalIntegerLiteral(%s)", this.source)
}

func (this *HexadecimalIntegerLiteral) String() string {
    return fmt.Sprintf("HexadecimalIntegerLiteral(%s)", this.source)
}

func (this *FloatLiteral) String() string {
    return fmt.Sprintf("FloatLiteral(%s)", this.source)
}

func (this *Eof) String() string {
    return "EOF()"
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
