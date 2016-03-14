package syntax

type TypeModifier interface {
    ModifyNamedType(*NamedType) Type
}

type ExpressionModifier interface {
    TypeModifier
    ModifyBooleanLiteral(*BooleanLiteral) Expression
    ModifyStringLiteral(*StringLiteral) Expression
    ModifyBinaryIntegerLiteral(*BinaryIntegerLiteral) Expression
    ModifyDecimalIntegerLiteral(*DecimalIntegerLiteral) Expression
    ModifyHexadecimalIntegerLiteral(*HexadecimalIntegerLiteral) Expression
    ModifyFloatLiteral(*FloatLiteral) Expression
    ModifyNameReference(*NameReference) Expression
    ModifyLabeledExpression(*LabeledExpression) Expression
    ModifyCompositeLiteral(*CompositeLiteral) Expression
    ModifyInitializer(*Initializer) Expression
    ModifyContextFieldAccess(*ContextFieldAccess) Expression
    ModifyFieldAccess(*FieldAccess) Expression
    ModifyArrayAccess(*ArrayAccess) Expression
    ModifyFunctionCall(*FunctionCall) Expression
    ModifySign(*Sign) Expression
    ModifyLogicalNot(*LogicalNot) Expression
    ModifyBitwiseNot(*BitwiseNot) Expression
    ModifyExponent(*Exponent) Expression
    ModifyInfix(*Infix) Expression
    ModifyMultiply(*Multiply) Expression
    ModifyAdd(*Add) Expression
    ModifyShift(*Shift) Expression
    ModifyCompare(*Compare) Expression
    ModifyBitwiseAnd(*BitwiseAnd) Expression
    ModifyBitwiseXor(*BitwiseXor) Expression
    ModifyBitwiseOr(*BitwiseOr) Expression
    ModifyLogicalAnd(*LogicalAnd) Expression
    ModifyLogicalXor(*LogicalXor) Expression
    ModifyLogicalOr(*LogicalOr) Expression
    ModifyConcatenate(*Concatenate) Expression
    ModifyRange(*Range) Expression
    ModifyConditional(*Conditional) Expression
}

type StatementModifier interface {
    ExpressionModifier
    ModifyInitializerAssignment(*InitializerAssignment) Statement
    ModifyAssignment(*Assignment) Statement
    ModifyFunctionCallStatement(*FunctionCallStatement) Statement
}

func (this *NamedType) Accept(visitor TypeModifier) Type {
    return visitor.ModifyNamedType(this)
}

func (this *BooleanLiteral) Accept(visitor ExpressionModifier) Expression {
    return visitor.ModifyBooleanLiteral(this)
}

func (this *StringLiteral) Accept(visitor ExpressionModifier) Expression {
    return visitor.ModifyStringLiteral(this)
}

func (this *BinaryIntegerLiteral) Accept(visitor ExpressionModifier) Expression {
    return visitor.ModifyBinaryIntegerLiteral(this)
}

func (this *DecimalIntegerLiteral) Accept(visitor ExpressionModifier) Expression {
    return visitor.ModifyDecimalIntegerLiteral(this)
}

func (this *HexadecimalIntegerLiteral) Accept(visitor ExpressionModifier) Expression {
    return visitor.ModifyHexadecimalIntegerLiteral(this)
}

func (this *FloatLiteral) Accept(visitor ExpressionModifier) Expression {
    return visitor.ModifyFloatLiteral(this)
}

func (this *NameReference) Accept(visitor ExpressionModifier) Expression {
    return visitor.ModifyNameReference(this)
}

func (this *CompositeLiteral) Accept(visitor ExpressionModifier) Expression {
    for i := 0; i < len(this.Values); i++ {
        this.Values[i].Value = this.Values[i].Value.Accept(visitor)
    }
    return visitor.ModifyCompositeLiteral(this)
}

func (this *Initializer) Accept(visitor ExpressionModifier) Expression {
    this.Type = this.Type.Accept(visitor).(*NamedType)
    this.Value = this.Value.Accept(visitor).(*CompositeLiteral)
    return visitor.ModifyInitializer(this)
}

func (this *ContextFieldAccess) Accept(visitor ExpressionModifier) Expression {
    return visitor.ModifyContextFieldAccess(this)
}

func (this *FieldAccess) Accept(visitor ExpressionModifier) Expression {
    this.Value = this.Value.Accept(visitor)
    return visitor.ModifyFieldAccess(this)
}

func (this *ArrayAccess) Accept(visitor ExpressionModifier) Expression {
    this.Value = this.Value.Accept(visitor)
    return visitor.ModifyArrayAccess(this)
}

func (this *FunctionCall) Accept(visitor ExpressionModifier) Expression {
    this.Value = this.Value.Accept(visitor)
    for i := 0; i < len(this.Arguments); i++ {
        this.Arguments[i] = this.Arguments[i].Accept(visitor)
    }
    return visitor.ModifyFunctionCall(this)
}

func (this *Sign) Accept(visitor ExpressionModifier) Expression {
    this.Inner = this.Inner.Accept(visitor)
    return visitor.ModifySign(this)
}

func (this *LogicalNot) Accept(visitor ExpressionModifier) Expression {
    this.Inner = this.Inner.Accept(visitor)
    return visitor.ModifyLogicalNot(this)
}

func (this *BitwiseNot) Accept(visitor ExpressionModifier) Expression {
    this.Inner = this.Inner.Accept(visitor)
    return visitor.ModifyBitwiseNot(this)
}

func (this *Exponent) Accept(visitor ExpressionModifier) Expression {
    this.Value = this.Value.Accept(visitor)
    this.Exponent = this.Exponent.Accept(visitor)
    return visitor.ModifyExponent(this)
}

func (this *Infix) Accept(visitor ExpressionModifier) Expression {
    this.Value = this.Value.Accept(visitor)
    this.Argument = this.Argument.Accept(visitor)
    return visitor.ModifyInfix(this)
}

func (this *Multiply) Accept(visitor ExpressionModifier) Expression {
    this.Left = this.Left.Accept(visitor)
    this.Right = this.Right.Accept(visitor)
    return visitor.ModifyMultiply(this)
}

func (this *Add) Accept(visitor ExpressionModifier) Expression {
    this.Left = this.Left.Accept(visitor)
    this.Right = this.Right.Accept(visitor)
    return visitor.ModifyAdd(this)
}

func (this *Shift) Accept(visitor ExpressionModifier) Expression {
    this.Value = this.Value.Accept(visitor)
    this.Amount = this.Amount.Accept(visitor)
    return visitor.ModifyShift(this)
}

func (this *Compare) Accept(visitor ExpressionModifier) Expression {
    for i := 0; i < len(this.Values); i++ {
        this.Values[i] = this.Values[i].Accept(visitor)
    }
    this.Type = this.Type.Accept(visitor)
    return visitor.ModifyCompare(this)
}

func (this *BitwiseAnd) Accept(visitor ExpressionModifier) Expression {
    this.Left = this.Left.Accept(visitor)
    this.Right = this.Right.Accept(visitor)
    return visitor.ModifyBitwiseAnd(this)
}

func (this *BitwiseXor) Accept(visitor ExpressionModifier) Expression {
    this.Left = this.Left.Accept(visitor)
    this.Right = this.Right.Accept(visitor)
    return visitor.ModifyBitwiseXor(this)
}

func (this *BitwiseOr) Accept(visitor ExpressionModifier) Expression {
    this.Left = this.Left.Accept(visitor)
    this.Right = this.Right.Accept(visitor)
    return visitor.ModifyBitwiseOr(this)
}

func (this *LogicalAnd) Accept(visitor ExpressionModifier) Expression {
    this.Left = this.Left.Accept(visitor)
    this.Right = this.Right.Accept(visitor)
    return visitor.ModifyLogicalAnd(this)
}

func (this *LogicalXor) Accept(visitor ExpressionModifier) Expression {
    this.Left = this.Left.Accept(visitor)
    this.Right = this.Right.Accept(visitor)
    return visitor.ModifyLogicalXor(this)
}

func (this *LogicalOr) Accept(visitor ExpressionModifier) Expression {
    this.Left = this.Left.Accept(visitor)
    this.Right = this.Right.Accept(visitor)
    return visitor.ModifyLogicalOr(this)
}

func (this *Concatenate) Accept(visitor ExpressionModifier) Expression {
    this.Left = this.Left.Accept(visitor)
    this.Right = this.Right.Accept(visitor)
    return visitor.ModifyConcatenate(this)
}

func (this *Range) Accept(visitor ExpressionModifier) Expression {
    this.From = this.From.Accept(visitor)
    this.To = this.To.Accept(visitor)
    return visitor.ModifyRange(this)
}

func (this *Conditional) Accept(visitor ExpressionModifier) Expression {
    this.Condition = this.Condition.Accept(visitor)
    this.TrueValue = this.TrueValue.Accept(visitor)
    this.FalseValue = this.FalseValue.Accept(visitor)
    return visitor.ModifyConditional(this)
}

func (this *InitializerAssignment) Accept(visitor StatementModifier) Statement {
    this.Target = this.Target.Accept(visitor)
    this.Literal = this.Literal.Accept(visitor).(*CompositeLiteral)
    return visitor.ModifyInitializerAssignment(this)
}

func (this *Assignment) Accept(visitor StatementModifier) Statement {
    this.Target = this.Target.Accept(visitor)
    this.Value = this.Value.Accept(visitor)
    return visitor.ModifyAssignment(this)
}

func (this *FunctionCallStatement) Accept(visitor StatementModifier) Statement {
    this.Value = this.Value.Accept(visitor)
    for i := 0; i < len(this.Arguments); i++ {
        this.Arguments[i] = this.Arguments[i].Accept(visitor)
    }
    return visitor.ModifyFunctionCallStatement(this)
}
