package syntax

import (
    "fmt"
    "strings"
    "strconv"
    "math/big"
)

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
    INTEGER_LITERAL
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
    value bool
    evaluated bool
}

type StringLiteral struct {
    Source_
    runeSource []rune
    value []rune
    evaluated bool
}

type IntegerLiteral struct {
    Source_
    value *big.Int
}

type FloatLiteral struct {
    Source_
    value *big.Rat
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
    return &BooleanLiteral{Source_{string(source)}, false, false}
}

func NewStringLiteral(source []rune) *StringLiteral {
    return &StringLiteral{Source_{string(source)}, source, nil, false}
}

func NewIntegerLiteral(source []rune) *IntegerLiteral {
    return &IntegerLiteral{Source_{string(source)}, nil}
}

func NewFloatLiteral(source []rune) *FloatLiteral {
    return &FloatLiteral{Source_{string(source)}, nil}
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

func (this *IntegerLiteral) Kind() Kind {
    return INTEGER_LITERAL
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
func (this *IntegerLiteral) String() string {
    return fmt.Sprintf("IntegerLiteral(%s)", this.source)
}

func (this *FloatLiteral) String() string {
    return fmt.Sprintf("FloatLiteral(%s)", this.source)
}

func (this *Eof) String() string {
    return "EOF()"
}

func (this *BooleanLiteral) Value() bool {
    if !this.evaluated {
        switch this.Source() {
        case "false":
            this.value = false
        case "true":
            this.value = true
        default:
            panic("Not a boolean")
        }
        this.evaluated = true
    }
    return this.value
}

func (this *StringLiteral) Value() []rune {
    if this.evaluated {
        return this.value
    }
    length := len(this.runeSource)
    if length < 2 {
        panic("String is missing enclosing quotes")
    }
    if this.runeSource[0] != '"' {
        panic("String is missing beginning quote")
    }
    value := []rune{}
    for i := 1; i < length - 1; {
        c := this.runeSource[i]
        i += 1
        if c == '\\' {
            c = this.runeSource[i]
            i += 1
            if c == 'u' {
                var j int
                c, j = decodeUnicodeEscape(this.runeSource[i - 1:])
                i += j
            } else {
                c = decodeCharEscape(c)
            }
        }
        value = append(value, c)
    }
    if this.runeSource[length - 1] != '"' {
        panic("String is missing ending quote")
    }
    this.value = value
    this.evaluated = true
    return value
}

func decodeUnicodeEscape(cs []rune) (rune, int) {
    length := len(cs)
    if length < 2 || cs[0] != 'u' {
        panic("Not a valid unicode escape")
    }
    i := 1
    for i < length && i < 9 && isHexDigit(cs[i]) {
        i += 1
    }
    val, ok := strconv.ParseUint(string(cs[1:i]), 16, 32)
    if ok != nil {
        panic("Failed to parse unicode escape")
    }
    return rune(val), i - 1
}

func decodeCharEscape(c rune) rune {
    switch c {
    case 'a':
        return '\a'
    case 'b':
        return '\b'
    case 't':
        return '\t'
    case 'n':
        return '\n'
    case 'v':
        return '\v'
    case 'f':
        return '\f'
    case 'r':
        return '\r'
    case '"':
        return '"'
    case '\\':
        return '\\'
    default:
        panic("Not a valid escape character")
    }
}

func (this *IntegerLiteral) Value() *big.Int {
    if this.value == nil {
        v := strings.Replace(this.source, "_", "", -1)
        i := new(big.Int)
        _, ok := i.SetString(v, 0)
        if !ok {
            panic("Failed to parse integer literal")
        }
        this.value = i
    }
    return this.value
}

func (this *FloatLiteral) Value() *big.Rat {
    if this.value == nil {
        v := strings.Replace(this.source, "_", "", -1)
        i := new(big.Rat)
        _, ok := i.SetString(v)
        if !ok {
            panic("Failed to parse float literal")
        }
        this.value = i
    }
    return this.value
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
