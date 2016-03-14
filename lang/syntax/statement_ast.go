package syntax

import (
    "fmt"
)

type Statement interface {
    String() string
}

type InitializerAssignment struct {
    Target Expression
    Literal *CompositeLiteral
}

type Assignment struct {
    Target Expression
    Operator *Symbol
    Value Expression
}

func (this *InitializerAssignment) String() string {
    return fmt.Sprintf("InitializerAssignment(%s = %s)", this.Target.String(), this.Literal.String())
}

func (this *Assignment) String() string {
    return fmt.Sprintf("Assignment(%s %s %s)", this.Target.String(), this.Operator.Source(), this.Value.String())
}
