package syntax

type TypeVisitor interface {
    VisitNamedType(*NamedType)
}

type ExpressionVisitor interface {
    TypeVisitor
    VisitBooleanLiteral(*BooleanLiteral)
    VisitStringLiteral(*StringLiteral)
    VisitBinaryIntegerLiteral(*BinaryIntegerLiteral)
    VisitDecimalIntegerLiteral(*DecimalIntegerLiteral)
    VisitHexadecimalIntegerLiteral(*HexadecimalIntegerLiteral)
    VisitFloatLiteral(*FloatLiteral)
    VisitNameReference(*NameReference)
    VisitLabeledExpression(*LabeledExpression)
    VisitCompositeLiteral(*CompositeLiteral)
    VisitInitializer(*Initializer)
    VisitContextFieldAccess(*ContextFieldAccess)
    VisitFieldAccess(*FieldAccess)
    VisitArrayAccess(*ArrayAccess)
    VisitFunctionCall(*FunctionCall)
    VisitSign(*Sign)
    VisitLogicalNot(*LogicalNot)
    VisitBitwiseNot(*BitwiseNot)
    VisitExponent(*Exponent)
    VisitInfix(*Infix)
    VisitMultiply(*Multiply)
    VisitAdd(*Add)
    VisitShift(*Shift)
    VisitCompare(*Compare)
    VisitBitwiseAnd(*BitwiseAnd)
    VisitBitwiseXor(*BitwiseXor)
    VisitBitwiseOr(*BitwiseOr)
    VisitLogicalAnd(*LogicalAnd)
    VisitLogicalXor(*LogicalXor)
    VisitLogicalOr(*LogicalOr)
    VisitConcatenate(*Concatenate)
    VisitRange(*Range)
    VisitConditional(*Conditional)
}

type StatementVisitor interface {
    ExpressionVisitor
    VisitInitializerAssignment(*InitializerAssignment)
    VisitAssignment(*Assignment)
}
