package syntax

import (
    "fmt"
)

type Expression interface {
    String() string
}

type NameReference struct {
    Name []*IdentifierToken
}

type LabeledExpression struct {
    Label Token
    Value Expression
}

type CompositeLiteral struct {
    Values []*LabeledExpression
}

type Initializer struct {
    Type *NamedType
    Value *CompositeLiteral
}

type ContextFieldAccess struct {
    Name *IdentifierToken
}

type FieldAccess struct {
    Value Expression
    Name *IdentifierToken
}

type ArrayAccess struct {
    Value Expression
    Index Expression
}

type FunctionCall struct {
    Value Expression
    Arguments []Expression
}

type Sign struct {
    Operator *SymbolToken
    Inner Expression
}

type LogicalNot struct {
    Inner Expression
}

type BitwiseNot struct {
    Inner Expression
}

type Exponent struct {
    Value Expression
    Exponent Expression
}

type Infix struct {
    Value Expression
    Function *IdentifierToken
    Argument Expression
}

type Multiply struct {
    Left Expression
    Operator *SymbolToken
    Right Expression
}

type Add struct {
    Left Expression
    Operator *SymbolToken
    Right Expression
}

type Shift struct {
    Value Expression
    Operator *SymbolToken
    Amount Expression
}

type Compare struct {
    Values []Expression
    ValueOperators []*SymbolToken
    Type Type
    TypeOperator *SymbolToken
}

type BitwiseAnd struct {
    Left Expression
    Right Expression
}

type BitwiseXor struct {
    Left Expression
    Right Expression
}

type BitwiseOr struct {
    Left Expression
    Right Expression
}

type LogicalAnd struct {
    Left Expression
    Right Expression
}

type LogicalXor struct {
    Left Expression
    Right Expression
}

type LogicalOr struct {
    Left Expression
    Right Expression
}

type Concatenate struct {
    Left Expression
    Right Expression
}

type Range struct {
    From Expression
    To Expression
}

type Conditional struct {
    Condition Expression
    TrueValue Expression
    FalseValue Expression
}

func (this *NameReference) String() string {
    return joinSource(this.Name, ".")
}

func (this *LabeledExpression) String() string {
    labelString := ""
    if this.Label != nil {
        labelString = this.Label.Source() + ": "
    }
    return labelString + this.Value.String()
}

func (this *CompositeLiteral) String() string {
    return fmt.Sprintf("CompositeLiteral({%s})", joinString(this.Values, ", "))
}

func (this *Initializer) String() string {
    return fmt.Sprintf("Initializer(%s{%s})", this.Type.String(), joinString(this.Value.Values, ", "))
}

func (this *ContextFieldAccess) String() string {
    return fmt.Sprintf("ContextFieldAccess(.%s)", this.Name.Source())
}

func (this *FieldAccess) String() string {
    return fmt.Sprintf("FieldAccess(%s.%s)", this.Value.String(), this.Name.Source())
}

func (this *ArrayAccess) String() string {
    return fmt.Sprintf("ArrayAccess(%s[%s])", this.Value.String(), this.Index.String())
}

func (this *FunctionCall) String() string {
    return fmt.Sprintf("FunctionCall(%s(%s))", this.Value.String(), joinString(this.Arguments, ", "))
}

func (this *Sign) String() string {
    return fmt.Sprintf("Sign(%s%s)", this.Operator.Source(), this.Inner.String())
}

func (this *LogicalNot) String() string {
    return fmt.Sprintf("LogicalNot(!%s)", this.Inner.String())
}

func (this *BitwiseNot) String() string {
    return fmt.Sprintf("BitwiseNot(~%s)", this.Inner.String())
}

func (this *Exponent) String() string {
    return fmt.Sprintf("Exponent(%s ** %s)", this.Value.String(), this.Exponent.String())
}

func (this *Infix) String() string {
    return fmt.Sprintf("Infix(%s %s %s)", this.Value.String(), this.Function.Source(), this.Argument.String())
}

func (this *Multiply) String() string {
    return fmt.Sprintf("Multiply(%s %s %s)", this.Left.String(), this.Operator.Source(), this.Right.String())
}

func (this *Add) String() string {
    return fmt.Sprintf("Add(%s %s %s)", this.Left.String(), this.Operator.Source(), this.Right.String())
}

func (this *Shift) String() string {
    return fmt.Sprintf("Shift(%s %s %s)", this.Value.String(), this.Operator.Source(), this.Amount.String())
}

func (this *Compare) String() string {
    s := "Compare("
    for i, operator := range this.ValueOperators {
        s += fmt.Sprintf("%s %s ", this.Values[i].String(), operator.Source())
    }
    s += this.Values[len(this.Values) - 1].String()
    if this.TypeOperator != nil {
        s += fmt.Sprintf(" %s %s)", this.TypeOperator.Source(), this.Type.String())
    } else {
        s += ")"
    }
    return s
}

func (this *BitwiseAnd) String() string {
    return fmt.Sprintf("BitwiseAnd(%s & %s)", this.Left.String(), this.Right.String())
}

func (this *BitwiseXor) String() string {
    return fmt.Sprintf("BitwiseXor(%s ^ %s)", this.Left.String(), this.Right.String())
}

func (this *BitwiseOr) String() string {
    return fmt.Sprintf("BitwiseOr(%s | %s)", this.Left.String(), this.Right.String())
}

func (this *LogicalAnd) String() string {
    return fmt.Sprintf("LogicalAnd(%s && %s)", this.Left.String(), this.Right.String())
}

func (this *LogicalXor) String() string {
    return fmt.Sprintf("LogicalXor(%s ^^ %s)", this.Left.String(), this.Right.String())
}

func (this *LogicalOr) String() string {
    return fmt.Sprintf("LogicalOr(%s || %s)", this.Left.String(), this.Right.String())
}

func (this *Concatenate) String() string {
    return fmt.Sprintf("Concatenate(%s ~ %s)", this.Left.String(), this.Right.String())
}

func (this *Range) String() string {
    return fmt.Sprintf("Range(%s .. %s)", this.From.String(), this.To.String())
}

func (this *Conditional) String() string {
    return fmt.Sprintf("Conditional(%s if %s else %s)", this.TrueValue.String(), this.Condition.String(), this.FalseValue.String())
}
