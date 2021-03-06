module ruleslang.syntax.ast.mapper;

import ruleslang.syntax.token;
import ruleslang.syntax.ast.type;
import ruleslang.syntax.ast.expression;
import ruleslang.syntax.ast.statement;
import ruleslang.syntax.ast.rule;

public abstract class TypeAstMapper {
    public TypeAst mapNamedType(NamedTypeAst type) {
        return type;
    }

    public TypeAst mapAnyType(AnyTypeAst type) {
        return type;
    }

    public TypeAst mapTupleType(TupleTypeAst type) {
        return type;
    }

    public TypeAst mapStructType(StructTypeAst type) {
        return type;
    }
}

public abstract class ExpressionMapper : TypeAstMapper {
    public Expression mapNullLiteral(NullLiteral expression) {
        return expression;
    }

    public Expression mapBooleanLiteral(BooleanLiteral expression) {
        return expression;
    }

    public Expression mapStringLiteral(StringLiteral expression) {
        return expression;
    }

    public Expression mapCharacterLiteral(CharacterLiteral expression) {
        return expression;
    }

    public Expression mapSignedIntegerLiteral(SignedIntegerLiteral expression) {
        return expression;
    }

    public Expression mapUnsignedIntegerLiteral(UnsignedIntegerLiteral expression) {
        return expression;
    }

    public Expression mapFloatLiteral(FloatLiteral expression) {
        return expression;
    }

    public Expression mapNameReference(NameReference expression) {
        return expression;
    }

    public Expression mapCompositeLiteral(CompositeLiteral expression) {
        return expression;
    }

    public Expression mapInitializer(Initializer expression) {
        return expression;
    }

    public Expression mapContextMemberAccess(ContextMemberAccess expression) {
        return expression;
    }

    public Expression mapMemberAccess(MemberAccess expression) {
        return expression;
    }

    public Expression mapIndexAccess(IndexAccess expression) {
        return expression;
    }

    public Expression mapFunctionCall(FunctionCall expression) {
        return expression;
    }

    public Expression mapSign(Sign expression) {
        return expression;
    }

    public Expression mapLogicalNot(LogicalNot expression) {
        return expression;
    }

    public Expression mapBitwiseNot(BitwiseNot expression) {
        return expression;
    }

    public Expression mapExponent(Exponent expression) {
        return expression;
    }

    public Expression mapInfix(Infix expression) {
        return expression;
    }

    public Expression mapMultiply(Multiply expression) {
        return expression;
    }

    public Expression mapAdd(Add expression) {
        return expression;
    }

    public Expression mapShift(Shift expression) {
        return expression;
    }

    public Expression mapCompare(Compare expression) {
        return expression;
    }

    public Expression mapValueCompare(ValueCompare expression) {
        return expression;
    }

    public Expression mapTypeCompare(TypeCompare expression) {
        return expression;
    }

    public Expression mapBitwiseAnd(BitwiseAnd expression) {
        return expression;
    }

    public Expression mapBitwiseXor(BitwiseXor expression) {
        return expression;
    }

    public Expression mapBitwiseOr(BitwiseOr expression) {
        return expression;
    }

    public Expression mapLogicalAnd(LogicalAnd expression) {
        return expression;
    }

    public Expression mapLogicalXor(LogicalXor expression) {
        return expression;
    }

    public Expression mapLogicalOr(LogicalOr expression) {
        return expression;
    }

    public Expression mapConcatenate(Concatenate expression) {
        return expression;
    }

    public Expression mapRange(Range expression) {
        return expression;
    }

    public Expression mapConditional(Conditional expression) {
        return expression;
    }
}

public abstract class StatementMapper : ExpressionMapper {
    public Statement mapTypeDefinition(TypeDefinition statement) {
        return statement;
    }

    public Statement mapFunctionCallStatement(FunctionCallStatement statement) {
        return statement;
    }

    public Statement mapVariableDeclaration(VariableDeclaration statement) {
        return statement;
    }

    public Statement mapAssignment(Assignment statement) {
        return statement;
    }

    public Statement mapConditionalStatement(ConditionalStatement statement) {
        return statement;
    }

    public Statement mapLoopStatement(LoopStatement statement) {
        return statement;
    }

    public Statement mapFunctionDefinition(FunctionDefinition statement) {
        return statement;
    }

    public Statement mapReturnStatement(ReturnStatement statement) {
        return statement;
    }

    public Statement mapBreakStatement(BreakStatement statement) {
        return statement;
    }

    public Statement mapContinueStatement(ContinueStatement statement) {
        return statement;
    }

    public Statement mapWhenDefinition(WhenDefinition statement) {
        return statement;
    }

    public Statement mapThenDefinition(ThenDefinition statement) {
        return statement;
    }
}

public abstract class RuleMapper : StatementMapper {
    public Rule mapRule(Rule rule) {
        return rule;
    }
}
