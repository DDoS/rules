module ruleslang.syntax.ast.expression;

import std.format;
import std.algorithm.iteration;

import ruleslang.syntax.dchars;
import ruleslang.syntax.token;
import ruleslang.syntax.ast.type;
import ruleslang.syntax.ast.statement;
import ruleslang.syntax.ast.mapper;

public interface Expression {
    public Expression accept(ExpressionMapper mapper);
    public string toString();
}

public interface Reference : Expression {
}

public class NameReference : Reference {
    private Identifier[] name;

    public this(Identifier[] name) {
        this.name = name;
    }

    public override Expression accept(ExpressionMapper mapper) {
        return mapper.mapNameReference(this);
    }

    public override string toString() {
        return name.join!(".", "getSource()")();
    }
}

public class LabeledExpression {
    private Token label;
    private Expression expression;

    public this(Token label, Expression expression) {
        this.label = label;
        this.expression = expression;
    }

    public override string toString() {
        return (label is null ? "" : label.getSource() ~ ": ") ~ expression.toString();
    }
}

public class CompositeLiteral : Expression {
    private LabeledExpression[] values;

    public this(LabeledExpression[] values) {
        this.values = values;
    }

    public override Expression accept(ExpressionMapper mapper) {
        foreach (i, value; values) {
            values[i].expression = value.expression.accept(mapper);
        }
        return mapper.mapCompositeLiteral(this);
    }

    public override string toString() {
        return format("CompositeLiteral({%s})", values.join!", "());
    }
}

public class Initializer : Expression {
    private NamedType type;
    private CompositeLiteral literal;

    public this(NamedType type, CompositeLiteral literal) {
        this.type = type;
        this.literal = literal;
    }

    public override Expression accept(ExpressionMapper mapper) {
        type = cast(NamedType) type.accept(mapper);
        literal = cast(CompositeLiteral) literal.accept(mapper);
        return mapper.mapInitializer(this);
    }

    public override string toString() {
        return format("Initializer(%s{%s})", type.toString(), literal.values.join!", "());
    }
}

public class ContextMemberAccess : Reference {
    private Identifier name;

    public this(Identifier name) {
        this.name = name;
    }

    public override Expression accept(ExpressionMapper mapper) {
        return mapper.mapContextMemberAccess(this);
    }

    public override string toString() {
        return format("ContextMemberAccess(.%s)", name.getSource());
    }
}

public class MemberAccess : Reference {
    private Expression value;
    private Identifier name;

    public this(Expression value, Identifier name) {
        this.value = value;
        this.name = name;
    }

    public override Expression accept(ExpressionMapper mapper) {
        value = value.accept(mapper);
        return mapper.mapMemberAccess(this);
    }

    public override string toString() {
        return format("MemberAccess(%s.%s)", value.toString(), name.getSource());
    }
}

public class ArrayAccess : Reference {
    private Expression value;
    private Expression index;

    public this(Expression value, Expression index) {
        this.value = value;
        this.index = index;
    }

    public override Expression accept(ExpressionMapper mapper) {
        value = value.accept(mapper);
        index = index.accept(mapper);
        return mapper.mapArrayAccess(this);
    }

    public override string toString() {
        return format("ArrayAccess(%s[%s])", value.toString(), index.toString());
    }
}

public class FunctionCall : Expression, Statement {
    private Expression value;
    private Expression[] arguments;

    public this(Expression value, Expression[] arguments) {
        this.value = value;
        this.arguments = arguments;
    }

    public override Expression accept(ExpressionMapper mapper) {
        value = value.accept(mapper);
        foreach (i, argument; arguments) {
            arguments[i] = argument.accept(mapper);
        }
        return mapper.mapFunctionCall(this);
    }

    public override Statement accept(StatementMapper mapper) {
        return accept(mapper);
    }

    public override string toString() {
        return format("FunctionCall(%s(%s))", value.toString(), arguments.join!", "());
    }
}

public template Unary(string name, Op) {
    public class Unary : Expression {
        private Expression _inner;
        private Op _operator;

        public this(Expression inner, Op operator) {
            _inner = inner;
            _operator = operator;
        }

        @property public Expression inner() {
            return _inner;
        }

        @property public Op operator() {
            return _operator;
        }

        public override Expression accept(ExpressionMapper mapper) {
            _inner = _inner.accept(mapper);
            mixin("return mapper.map" ~ name ~ "(this);");
        }

        public override string toString() {
            return format(name ~ "(%s%s)", _operator.getSource(), _inner.toString());
        }
    }
}

public alias Sign = Unary!("Sign", AddOperator);
public alias BitwiseNot = Unary!("BitwiseNot", ConcatenateOperator);
public alias LogicalNot = Unary!("LogicalNot", LogicalNotOperator);

public template Binary(string name, Op) {
    public class Binary : Expression {
        private Expression _left;
        private Expression _right;
        private Op _operator;

        public this(Expression left, Expression right, Op operator) {
            _left = left;
            _right = right;
            _operator = operator;
        }

        @property public Expression left() {
            return _left;
        }

        @property public Expression right() {
            return _right;
        }

        @property public Op operator() {
            return _operator;
        }

        public override Expression accept(ExpressionMapper mapper) {
            _left = _left.accept(mapper);
            _right = _right.accept(mapper);
            mixin("return mapper.map" ~ name ~ "(this);");
        }

        public override string toString() {
            return format(name ~ "(%s %s %s)", _left.toString(), _operator.getSource(), _right.toString());
        }
    }
}

public alias Exponent = Binary!("Exponent", ExponentOperator);
public alias Infix = Binary!("Infix", Identifier);
public alias Multiply = Binary!("Multiply", MultiplyOperator);
public alias Add = Binary!("Add", AddOperator);
public alias Shift = Binary!("Shift", ShiftOperator);
public alias BitwiseAnd = Binary!("BitwiseAnd", BitwiseAndOperator);
public alias BitwiseXor = Binary!("BitwiseXor", BitwiseXorOperator);
public alias BitwiseOr = Binary!("BitwiseOr", BitwiseOrOperator);
public alias LogicalAnd = Binary!("LogicalAnd", LogicalAndOperator);
public alias LogicalXor = Binary!("LogicalXor", LogicalXorOperator);
public alias LogicalOr = Binary!("LogicalOr", LogicalOrOperator);
public alias Concatenate = Binary!("Concatenate", ConcatenateOperator);
public alias Range = Binary!("Range", RangOperator);

public class Compare : Expression {
    private Expression[] values;
    private ValueCompareOperator[] valueOperators;
    private Type type;
    private TypeCompareOperator typeOperator;

    public this(Expression[] values, ValueCompareOperator[] valueOperators, Type type, TypeCompareOperator typeOperator) {
        this.values = values;
        this.valueOperators = valueOperators;
        this.type = type;
        this.typeOperator = typeOperator;
    }

    public override Expression accept(ExpressionMapper mapper) {
        foreach (i, value; values) {
            values[i] = value.accept(mapper);
        }
        type = type.accept(mapper);
        return mapper.mapCompare(this);
    }

    public override string toString() {
        string compares = "";
        foreach (i, valueOperator; valueOperators) {
            compares ~= format("%s %s ", values[i].toString(), valueOperator.getSource());
        }
        compares ~= values[$ - 1].toString();
        if (typeOperator !is null) {
            compares ~= format(" %s %s", typeOperator.getSource(), type.toString());
        }
        return format("Compare(%s)", compares);
    }
}

public class Conditional : Expression {
    private Expression _condition;
    private Expression _trueValue;
    private Expression _falseValue;

    public this(Expression condition, Expression trueValue, Expression falseValue) {
        _condition = condition;
        _trueValue = trueValue;
        _falseValue = falseValue;
    }

    @property public Expression condition() {
        return _condition;
    }

    @property public Expression trueValue() {
        return _trueValue;
    }

    @property public Expression falseValue() {
        return _falseValue;
    }

    public override Expression accept(ExpressionMapper mapper) {
        _condition = _condition.accept(mapper);
        _trueValue = _trueValue.accept(mapper);
        _falseValue = _falseValue.accept(mapper);
        return mapper.mapConditional(this);
    }

    public override string toString() {
        return format("Conditional(%s if %s else %s)", _trueValue, _condition, _falseValue);
    }
}
