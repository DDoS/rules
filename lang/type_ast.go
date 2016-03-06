package lang

type Type interface {
    String() string
}

type NamedType struct {
    Name []*Token
    Dimensions []Expression
}

func (this *NamedType) String() string {
    dimensionsString := ""
    for _, dimension := range this.Dimensions {
        if dimension == nil {
            dimensionsString += "[]"
        } else {
            dimensionsString += "[" + dimension.String() + "]"
        }
    }
    return joinSource(this.Name, ".") + dimensionsString
}
