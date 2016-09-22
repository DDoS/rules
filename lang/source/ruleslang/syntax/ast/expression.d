module ruleslang.syntax.ast.expression;

import std.format : format;

import ruleslang.syntax.dchars;
import ruleslang.syntax.source;
import ruleslang.syntax.token;
import ruleslang.syntax.ast.type;
import ruleslang.syntax.ast.statement;
import ruleslang.syntax.ast.mapper;
import ruleslang.semantic.tree;
import ruleslang.semantic.context;
import ruleslang.semantic.interpret;
import ruleslang.util;

public interface Expression {
    @property public size_t start();
    @property public size_t end();
    @property public void start(size_t start);
    @property public void end(size_t end);
    public Expression map(ExpressionMapper mapper);
    public immutable(TypedNode) interpret(Context context);
    public string toString();
}

public interface AssignableExpression : Expression {
}

public class NameReference : AssignableExpression {
    private Identifier[] _name;

    public this(Identifier[] name) {
        assert (name.length > 0);
        _name = name;
        _start = name[0].start;
        _end = name[$ - 1].end;
    }

    @property public Identifier[] name() {
        return _name;
    }

    mixin sourceIndexFields;

    public override Expression map(ExpressionMapper mapper) {
        return mapper.mapNameReference(this);
    }

    public override immutable(TypedNode) interpret(Context context) {
        return Interpreter.INSTANCE.interpretNameReference(context, this);
    }

    public override string toString() {
        return _name.join!(".", "a.getSource()")();
    }
}

public class LabeledExpression {
    private Token _label;
    private Expression _expression;

    public this(Token label, Expression expression) {
        _label = label;
        _expression = expression;
        _start = label is null ? expression.start : label.start;
        _end = expression.end;
    }

    @property public Token label() {
        return _label;
    }

    @property public Expression expression() {
        return _expression;
    }

    mixin sourceIndexFields;

    public override string toString() {
        return (_label is null ? "" : _label.getSource() ~ ": ") ~ _expression.toString();
    }
}

public class CompositeLiteral : Expression {
    private LabeledExpression[] _values;

    public this(LabeledExpression[] values, size_t start, size_t end) {
        _values = values;
        _start = start;
        _end = end;
    }

    @property public LabeledExpression[] values() {
        return _values;
    }

    mixin sourceIndexFields;

    public override Expression map(ExpressionMapper mapper) {
        foreach (i, value; _values) {
            _values[i]._expression = value._expression.map(mapper);
        }
        return mapper.mapCompositeLiteral(this);
    }

    public override immutable(TypedNode) interpret(Context context) {
        return Interpreter.INSTANCE.interpretCompositeLiteral(context, this);
    }

    public override string toString() {
        return format("CompositeLiteral({%s})", _values.join!", "());
    }
}

public class Initializer : Expression {
    private NamedTypeAst _type;
    private CompositeLiteral _literal;

    public this(NamedTypeAst type, CompositeLiteral literal) {
        _type = type;
        _literal = literal;
        _start = type.start;
        _end = literal.end;
    }

    @property public NamedTypeAst type() {
        return _type;
    }

    @property public CompositeLiteral literal() {
        return _literal;
    }

    mixin sourceIndexFields;

    public override Expression map(ExpressionMapper mapper) {
        _type = _type.map(mapper).castOrFail!NamedTypeAst();
        _literal = _literal.map(mapper).castOrFail!CompositeLiteral();
        return mapper.mapInitializer(this);
    }

    public override immutable(TypedNode) interpret(Context context) {
        return Interpreter.INSTANCE.interpretInitializer(context, this);
    }

    public override string toString() {
        return format("Initializer(%s{%s})", _type.toString(), _literal.values.join!", "());
    }
}

public class ContextMemberAccess : AssignableExpression {
    private Identifier name;

    public this(Identifier name, size_t start) {
        this.name = name;
        _start = start;
        _end = name.end;
    }

    mixin sourceIndexFields;

    public override Expression map(ExpressionMapper mapper) {
        return mapper.mapContextMemberAccess(this);
    }

    public override immutable(TypedNode) interpret(Context context) {
        return Interpreter.INSTANCE.interpretContextMemberAccess(context, this);
    }

    public override string toString() {
        return format("ContextMemberAccess(.%s)", name.getSource());
    }
}

public class MemberAccess : AssignableExpression {
    private Expression _value;
    private Identifier _name;

    public this(Expression value, Identifier name) {
        _value = value;
        _name = name;
        _start = value.start;
        _end = name.end;
    }

    @property public Expression value() {
        return _value;
    }

    @property public Identifier name() {
        return _name;
    }

    mixin sourceIndexFields;

    public override Expression map(ExpressionMapper mapper) {
        _value = _value.map(mapper);
        return mapper.mapMemberAccess(this);
    }

    public override immutable(TypedNode) interpret(Context context) {
        return Interpreter.INSTANCE.interpretMemberAccess(context, this);
    }

    public override string toString() {
        return format("MemberAccess(%s.%s)", _value.toString(), _name.getSource());
    }
}

public class IndexAccess : AssignableExpression {
    private Expression _value;
    private Expression _index;

    public this(Expression value, Expression index, size_t end) {
        _value = value;
        _index = index;
        _start = value.start;
        _end = end;
    }

    @property public Expression value() {
        return _value;
    }

    @property public Expression index() {
        return _index;
    }

    mixin sourceIndexFields;

    public override Expression map(ExpressionMapper mapper) {
        _value = _value.map(mapper);
        _index = _index.map(mapper);
        return mapper.mapIndexAccess(this);
    }

    public override immutable(TypedNode) interpret(Context context) {
        return Interpreter.INSTANCE.interpretIndexAccess(context, this);
    }

    public override string toString() {
        return format("IndexAccess(%s[%s])", _value.toString(), _index.toString());
    }
}

public class FunctionCall : Expression, Statement {
    private Expression _value;
    private Expression[] _arguments;

    public this(Expression value, Expression[] arguments, size_t end) {
        this(value, arguments, value.start, end);
    }

    public this(Expression value, Expression[] arguments, size_t start, size_t end) {
        _value = value;
        _arguments = arguments;
        _start = start;
        _end = end;
    }

    @property public Expression value() {
        return _value;
    }

    @property public Expression[] arguments() {
        return _arguments;
    }

    mixin sourceIndexFields;

    public override Expression map(ExpressionMapper mapper) {
        _value = _value.map(mapper);
        foreach (i, argument; _arguments) {
            _arguments[i] = argument.map(mapper);
        }
        return mapper.mapFunctionCall(this);
    }

    public override immutable(TypedNode) interpret(Context context) {
        return Interpreter.INSTANCE.interpretFunctionCall(context, this);
    }

    public override Statement map(StatementMapper mapper) {
        return map(mapper.castOrFail!ExpressionMapper()).castOrFail!Statement();
    }

    public override string toString() {
        return format("FunctionCall(%s(%s))", _value.toString(), _arguments.join!", "());
    }
}

public template Unary(string name, Op) {
    public class Unary : Expression {
        private Expression _inner;
        private Op _operator;

        public this(Expression inner, Op operator) {
            _inner = inner;
            _operator = operator;
            _start = operator.start;
            _end = inner.end;
        }

        @property public Expression inner() {
            return _inner;
        }

        @property public Op operator() {
            return _operator;
        }

        mixin sourceIndexFields;

        public override Expression map(ExpressionMapper mapper) {
            _inner = _inner.map(mapper);
            mixin("return mapper.map" ~ name ~ "(this);");
        }

        public override immutable(TypedNode) interpret(Context context) {
            mixin("return Interpreter.INSTANCE.interpret" ~ name ~ "(context, this);");
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
            _start = left.start;
            _end = right.end;
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

        mixin sourceIndexFields;

        public override Expression map(ExpressionMapper mapper) {
            _left = _left.map(mapper);
            _right = _right.map(mapper);
            mixin("return mapper.map" ~ name ~ "(this);");
        }

        public override immutable(TypedNode) interpret(Context context) {
            mixin("return Interpreter.INSTANCE.interpret" ~ name ~ "(context, this);");
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
public alias ValueCompare = Binary!("ValueCompare", ValueCompareOperator);

public class Compare : Expression {
    private Expression[] _values;
    private ValueCompareOperator[] _valueOperators;
    private TypeAst _type;
    private TypeCompareOperator _typeOperator;

    public this(Expression[] values, ValueCompareOperator[] valueOperators, TypeAst type, TypeCompareOperator typeOperator) {
        _values = values;
        _valueOperators = valueOperators;
        _type = type;
        _typeOperator = typeOperator;
        _start = values[0].start;
        _end = type is null ? values[$ - 1].end : type.end;
    }

    @property public Expression[] values() {
        return _values;
    }

    @property public ValueCompareOperator[] valueOperators() {
        return _valueOperators;
    }

    @property public TypeAst type() {
        return _type;
    }

    @property public TypeCompareOperator typeOperator() {
        return _typeOperator;
    }

    mixin sourceIndexFields;

    public override Expression map(ExpressionMapper mapper) {
        foreach (i, value; _values) {
            _values[i] = value.map(mapper);
        }
        if (type !is null) {
            _type = _type.map(mapper);
        }
        return mapper.mapCompare(this);
    }

    public override immutable(TypedNode) interpret(Context context) {
        return Interpreter.INSTANCE.interpretCompare(context, this);
    }

    public override string toString() {
        string compares = "";
        foreach (i, valueOperator; _valueOperators) {
            compares ~= format("%s %s ", _values[i].toString(), valueOperator.getSource());
        }
        compares ~= values[$ - 1].toString();
        if (_typeOperator !is null) {
            compares ~= format(" %s %s", _typeOperator.getSource(), _type.toString());
        }
        return format("Compare(%s)", compares);
    }
}

public class TypeCompare : Expression {
    private Expression _value;
    private TypeAst _type;
    private TypeCompareOperator _operator;

    public this(Expression value, TypeAst type, TypeCompareOperator operator) {
        _value = value;
        _type = type;
        _operator = operator;
        _start = value.start;
        _end = type.end;
    }

    @property public Expression value() {
        return _value;
    }

    @property public TypeAst type() {
        return _type;
    }

    @property public TypeCompareOperator operator() {
        return _operator;
    }

    mixin sourceIndexFields;

    public override Expression map(ExpressionMapper mapper) {
        _value = _value.map(mapper);
        _type = _type.map(mapper);
        return mapper.mapTypeCompare(this);
    }

    public override immutable(TypedNode) interpret(Context context) {
        return Interpreter.INSTANCE.interpretTypeCompare(context, this);
    }

    public override string toString() {
        return format("TypeCompare(%s %s %s)", _value.toString(), _operator.getSource(), _type.toString());
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
        _start = trueValue.start;
        _end = falseValue.end;
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

    mixin sourceIndexFields;

    public override Expression map(ExpressionMapper mapper) {
        _condition = _condition.map(mapper);
        _trueValue = _trueValue.map(mapper);
        _falseValue = _falseValue.map(mapper);
        return mapper.mapConditional(this);
    }

    public override immutable(TypedNode) interpret(Context context) {
        return Interpreter.INSTANCE.interpretConditional(context, this);
    }

    public override string toString() {
        return format("Conditional(%s if %s else %s)", _trueValue, _condition, _falseValue);
    }
}
