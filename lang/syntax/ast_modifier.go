package syntax

type TypeModifier struct {
    ModifyNamedType func(*NamedType) Type
}

type ExpressionModifier struct {
    *TypeModifier
    ModifyBooleanLiteral func(*BooleanLiteral) Expression
    ModifyStringLiteral func(*StringLiteral) Expression
    ModifyIntegerLiteral func(*IntegerLiteral) Expression
    ModifyFloatLiteral func(*FloatLiteral) Expression
    ModifyNameReference func(*NameReference) Expression
    ModifyCompositeLiteral func(*CompositeLiteral) Expression
    ModifyInitializer func(*Initializer) Expression
    ModifyContextFieldAccess func(*ContextFieldAccess) Expression
    ModifyFieldAccess func(*FieldAccess) Expression
    ModifyArrayAccess func(*ArrayAccess) Expression
    ModifyFunctionCall func(*FunctionCall) Expression
    ModifySign func(*Sign) Expression
    ModifyLogicalNot func(*LogicalNot) Expression
    ModifyBitwiseNot func(*BitwiseNot) Expression
    ModifyExponent func(*Exponent) Expression
    ModifyInfix func(*Infix) Expression
    ModifyMultiply func(*Multiply) Expression
    ModifyAdd func(*Add) Expression
    ModifyShift func(*Shift) Expression
    ModifyCompare func(*Compare) Expression
    ModifyBitwiseAnd func(*BitwiseAnd) Expression
    ModifyBitwiseXor func(*BitwiseXor) Expression
    ModifyBitwiseOr func(*BitwiseOr) Expression
    ModifyLogicalAnd func(*LogicalAnd) Expression
    ModifyLogicalXor func(*LogicalXor) Expression
    ModifyLogicalOr func(*LogicalOr) Expression
    ModifyConcatenate func(*Concatenate) Expression
    ModifyRange func(*Range) Expression
    ModifyConditional func(*Conditional) Expression
}

type StatementModifier struct {
    *ExpressionModifier
    ModifyInitializerAssignment func(*InitializerAssignment) Statement
    ModifyAssignment func(*Assignment) Statement
    ModifyFunctionCallStatement func(*FunctionCallStatement) Statement
}

func NewTypeModifier() *TypeModifier {
    return &TypeModifier{noopModifyNamedType}
}

func NewExpressionModifier() *ExpressionModifier {
    return &ExpressionModifier{
        NewTypeModifier(),
        noopModifyBooleanLiteral, noopModifyStringLiteral, noopModifyIntegerLiteral, noopModifyFloatLiteral,
        noopModifyNameReference, noopModifyCompositeLiteral, noopModifyInitializer, noopModifyContextFieldAccess,
        noopModifyFieldAccess, noopModifyArrayAccess, noopModifyFunctionCall, noopModifySign,
        noopModifyLogicalNot, noopModifyBitwiseNot, noopModifyExponent, noopModifyInfix,
        noopModifyMultiply, noopModifyAdd, noopModifyShift, noopModifyCompare,
        noopModifyBitwiseAnd, noopModifyBitwiseXor, noopModifyBitwiseOr, noopModifyLogicalAnd,
        noopModifyLogicalXor, noopModifyLogicalOr, noopModifyConcatenate, noopModifyRange,
        noopModifyConditional,
    }
}

func NewStatementModifier() *StatementModifier {
    return &StatementModifier{
        NewExpressionModifier(),
        noopModifyInitializerAssignment, noopModifyAssignment, noopModifyFunctionCallStatement,
    }
}

func (this *NamedType) Accept(visitor *TypeModifier) Type {
    return visitor.ModifyNamedType(this)
}

func (this *BooleanLiteral) Accept(visitor *ExpressionModifier) Expression {
    return visitor.ModifyBooleanLiteral(this)
}

func (this *StringLiteral) Accept(visitor *ExpressionModifier) Expression {
    return visitor.ModifyStringLiteral(this)
}

func (this *IntegerLiteral) Accept(visitor *ExpressionModifier) Expression {
    return visitor.ModifyIntegerLiteral(this)
}

func (this *FloatLiteral) Accept(visitor *ExpressionModifier) Expression {
    return visitor.ModifyFloatLiteral(this)
}

func (this *NameReference) Accept(visitor *ExpressionModifier) Expression {
    return visitor.ModifyNameReference(this)
}

func (this *CompositeLiteral) Accept(visitor *ExpressionModifier) Expression {
    for i := 0; i < len(this.Values); i++ {
        this.Values[i].Value = this.Values[i].Value.Accept(visitor)
    }
    return visitor.ModifyCompositeLiteral(this)
}

func (this *Initializer) Accept(visitor *ExpressionModifier) Expression {
    this.Type = this.Type.Accept(visitor.TypeModifier).(*NamedType)
    this.Value = this.Value.Accept(visitor).(*CompositeLiteral)
    return visitor.ModifyInitializer(this)
}

func (this *ContextFieldAccess) Accept(visitor *ExpressionModifier) Expression {
    return visitor.ModifyContextFieldAccess(this)
}

func (this *FieldAccess) Accept(visitor *ExpressionModifier) Expression {
    this.Value = this.Value.Accept(visitor)
    return visitor.ModifyFieldAccess(this)
}

func (this *ArrayAccess) Accept(visitor *ExpressionModifier) Expression {
    this.Value = this.Value.Accept(visitor)
    return visitor.ModifyArrayAccess(this)
}

func (this *FunctionCall) Accept(visitor *ExpressionModifier) Expression {
    this.Value = this.Value.Accept(visitor)
    for i := 0; i < len(this.Arguments); i++ {
        this.Arguments[i] = this.Arguments[i].Accept(visitor)
    }
    return visitor.ModifyFunctionCall(this)
}

func (this *Sign) Accept(visitor *ExpressionModifier) Expression {
    this.Inner = this.Inner.Accept(visitor)
    return visitor.ModifySign(this)
}

func (this *LogicalNot) Accept(visitor *ExpressionModifier) Expression {
    this.Inner = this.Inner.Accept(visitor)
    return visitor.ModifyLogicalNot(this)
}

func (this *BitwiseNot) Accept(visitor *ExpressionModifier) Expression {
    this.Inner = this.Inner.Accept(visitor)
    return visitor.ModifyBitwiseNot(this)
}

func (this *Exponent) Accept(visitor *ExpressionModifier) Expression {
    this.Value = this.Value.Accept(visitor)
    this.Exponent = this.Exponent.Accept(visitor)
    return visitor.ModifyExponent(this)
}

func (this *Infix) Accept(visitor *ExpressionModifier) Expression {
    this.Value = this.Value.Accept(visitor)
    this.Argument = this.Argument.Accept(visitor)
    return visitor.ModifyInfix(this)
}

func (this *Multiply) Accept(visitor *ExpressionModifier) Expression {
    this.Left = this.Left.Accept(visitor)
    this.Right = this.Right.Accept(visitor)
    return visitor.ModifyMultiply(this)
}

func (this *Add) Accept(visitor *ExpressionModifier) Expression {
    this.Left = this.Left.Accept(visitor)
    this.Right = this.Right.Accept(visitor)
    return visitor.ModifyAdd(this)
}

func (this *Shift) Accept(visitor *ExpressionModifier) Expression {
    this.Value = this.Value.Accept(visitor)
    this.Amount = this.Amount.Accept(visitor)
    return visitor.ModifyShift(this)
}

func (this *Compare) Accept(visitor *ExpressionModifier) Expression {
    for i := 0; i < len(this.Values); i++ {
        this.Values[i] = this.Values[i].Accept(visitor)
    }
    this.Type = this.Type.Accept(visitor.TypeModifier)
    return visitor.ModifyCompare(this)
}

func (this *BitwiseAnd) Accept(visitor *ExpressionModifier) Expression {
    this.Left = this.Left.Accept(visitor)
    this.Right = this.Right.Accept(visitor)
    return visitor.ModifyBitwiseAnd(this)
}

func (this *BitwiseXor) Accept(visitor *ExpressionModifier) Expression {
    this.Left = this.Left.Accept(visitor)
    this.Right = this.Right.Accept(visitor)
    return visitor.ModifyBitwiseXor(this)
}

func (this *BitwiseOr) Accept(visitor *ExpressionModifier) Expression {
    this.Left = this.Left.Accept(visitor)
    this.Right = this.Right.Accept(visitor)
    return visitor.ModifyBitwiseOr(this)
}

func (this *LogicalAnd) Accept(visitor *ExpressionModifier) Expression {
    this.Left = this.Left.Accept(visitor)
    this.Right = this.Right.Accept(visitor)
    return visitor.ModifyLogicalAnd(this)
}

func (this *LogicalXor) Accept(visitor *ExpressionModifier) Expression {
    this.Left = this.Left.Accept(visitor)
    this.Right = this.Right.Accept(visitor)
    return visitor.ModifyLogicalXor(this)
}

func (this *LogicalOr) Accept(visitor *ExpressionModifier) Expression {
    this.Left = this.Left.Accept(visitor)
    this.Right = this.Right.Accept(visitor)
    return visitor.ModifyLogicalOr(this)
}

func (this *Concatenate) Accept(visitor *ExpressionModifier) Expression {
    this.Left = this.Left.Accept(visitor)
    this.Right = this.Right.Accept(visitor)
    return visitor.ModifyConcatenate(this)
}

func (this *Range) Accept(visitor *ExpressionModifier) Expression {
    this.From = this.From.Accept(visitor)
    this.To = this.To.Accept(visitor)
    return visitor.ModifyRange(this)
}

func (this *Conditional) Accept(visitor *ExpressionModifier) Expression {
    this.Condition = this.Condition.Accept(visitor)
    this.TrueValue = this.TrueValue.Accept(visitor)
    this.FalseValue = this.FalseValue.Accept(visitor)
    return visitor.ModifyConditional(this)
}

func (this *InitializerAssignment) Accept(visitor *StatementModifier) Statement {
    this.Target = this.Target.Accept(visitor.ExpressionModifier)
    this.Literal = this.Literal.Accept(visitor.ExpressionModifier).(*CompositeLiteral)
    return visitor.ModifyInitializerAssignment(this)
}

func (this *Assignment) Accept(visitor *StatementModifier) Statement {
    this.Target = this.Target.Accept(visitor.ExpressionModifier)
    this.Value = this.Value.Accept(visitor.ExpressionModifier)
    return visitor.ModifyAssignment(this)
}

func (this *FunctionCallStatement) Accept(visitor *StatementModifier) Statement {
    this.Value = this.Value.Accept(visitor.ExpressionModifier)
    for i := 0; i < len(this.Arguments); i++ {
        this.Arguments[i] = this.Arguments[i].Accept(visitor.ExpressionModifier)
    }
    return visitor.ModifyFunctionCallStatement(this)
}

func noopModifyNamedType(type_ *NamedType) Type {
    return type_
}

func noopModifyBooleanLiteral(expression *BooleanLiteral) Expression {
    return expression
}

func noopModifyStringLiteral(expression *StringLiteral) Expression {
    return expression
}

func noopModifyIntegerLiteral(expression *IntegerLiteral) Expression {
    return expression
}

func noopModifyFloatLiteral(expression *FloatLiteral) Expression {
    return expression
}

func noopModifyNameReference(expression *NameReference) Expression {
    return expression
}

func noopModifyCompositeLiteral(expression *CompositeLiteral) Expression {
    return expression
}

func noopModifyInitializer(expression *Initializer) Expression {
    return expression
}

func noopModifyContextFieldAccess(expression *ContextFieldAccess) Expression {
    return expression
}

func noopModifyFieldAccess(expression *FieldAccess) Expression {
    return expression
}

func noopModifyArrayAccess(expression *ArrayAccess) Expression {
    return expression
}

func noopModifyFunctionCall(expression *FunctionCall) Expression {
    return expression
}

func noopModifySign(expression *Sign) Expression {
    return expression
}

func noopModifyLogicalNot(expression *LogicalNot) Expression {
    return expression
}

func noopModifyBitwiseNot(expression *BitwiseNot) Expression {
    return expression
}

func noopModifyExponent(expression *Exponent) Expression {
    return expression
}

func noopModifyInfix(expression *Infix) Expression {
    return expression
}

func noopModifyMultiply(expression *Multiply) Expression {
    return expression
}

func noopModifyAdd(expression *Add) Expression {
    return expression
}

func noopModifyShift(expression *Shift) Expression {
    return expression
}

func noopModifyCompare(expression *Compare) Expression {
    return expression
}

func noopModifyBitwiseAnd(expression *BitwiseAnd) Expression {
    return expression
}

func noopModifyBitwiseXor(expression *BitwiseXor) Expression {
    return expression
}

func noopModifyBitwiseOr(expression *BitwiseOr) Expression {
    return expression
}

func noopModifyLogicalAnd(expression *LogicalAnd) Expression {
    return expression
}

func noopModifyLogicalXor(expression *LogicalXor) Expression {
    return expression
}

func noopModifyLogicalOr(expression *LogicalOr) Expression {
    return expression
}

func noopModifyConcatenate(expression *Concatenate) Expression {
    return expression
}

func noopModifyRange(expression *Range) Expression {
    return expression
}

func noopModifyConditional(expression *Conditional) Expression {
    return expression
}

func noopModifyInitializerAssignment(statement *InitializerAssignment) Statement {
    return statement
}

func noopModifyAssignment(statement *Assignment) Statement {
    return statement
}

func noopModifyFunctionCallStatement(statement *FunctionCallStatement) Statement {
    return statement
}
