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

public interface Expression : SourceIndexed {
    public Expression map(ExpressionMapper mapper);
    public immutable(TypedNode) interpret(Context context);
    public string toString();
}

public interface Reference : Expression {
}

public class NameReference : Reference {
    private Identifier[] _name;

    public this(Identifier[] name) {
        assert (name.length > 0);
        _name = name;
    }

    @property public override size_t start() {
        return _name[0].start;
    }

    @property public override size_t end() {
        return _name[$ - 1].end;
    }

    @property public Identifier[] name() {
        return _name;
    }

    public override Expression map(ExpressionMapper mapper) {
        return mapper.mapNameReference(this);
    }

    public override immutable(TypedNode) interpret(Context context) {
        return Interpreter.INSTANCE.interpretNameReference(context, this);
    }

    public override string toString() {
        return _name.join!(".", "getSource()")();
    }
}

public class LabeledExpression {
    private Token label;
    private Expression expression;

    public this(Token label, Expression expression) {
        this.label = label;
        this.expression = expression;
    }

    @property public size_t start() {
        return label is null ? expression.start : label.start;
    }

    @property public size_t end() {
        return expression.end;
    }

    public override string toString() {
        return (label is null ? "" : label.getSource() ~ ": ") ~ expression.toString();
    }
}

public class CompositeLiteral : Expression {
    private LabeledExpression[] values;
    private size_t _start;
    private size_t _end;

    public this(LabeledExpression[] values, size_t start, size_t end) {
        this.values = values;
        _start = start;
        _end = end;
    }

    @property public override size_t start() {
        return _start;
    }

    @property public override size_t end() {
        return _end;
    }

    public override Expression map(ExpressionMapper mapper) {
        foreach (i, value; values) {
            values[i].expression = value.expression.map(mapper);
        }
        return mapper.mapCompositeLiteral(this);
    }

    public override immutable(TypedNode) interpret(Context context) {
        return Interpreter.INSTANCE.interpretCompositeLiteral(context, this);
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

    @property public override size_t start() {
        return type.start;
    }

    @property public override size_t end() {
        return literal.end;
    }

    public override Expression map(ExpressionMapper mapper) {
        type = type.map(mapper).castOrFail!NamedType();
        literal = literal.map(mapper).castOrFail!CompositeLiteral();
        return mapper.mapInitializer(this);
    }

    public override immutable(TypedNode) interpret(Context context) {
        return Interpreter.INSTANCE.interpretInitializer(context, this);
    }

    public override string toString() {
        return format("Initializer(%s{%s})", type.toString(), literal.values.join!", "());
    }
}

public class ContextMemberAccess : Reference {
    private Identifier name;
    private size_t _start;

    public this(Identifier name, size_t start) {
        this.name = name;
        _start = start;
    }

    @property public override size_t start() {
        return _start;
    }

    @property public override size_t end() {
        return name.end;
    }

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

public class MemberAccess : Reference {
    private Expression _value;
    private Identifier _name;

    public this(Expression value, Identifier name) {
        _value = value;
        _name = name;
    }

    @property public override size_t start() {
        return _value.start;
    }

    @property public override size_t end() {
        return _name.end;
    }

    @property public Expression value() {
        return _value;
    }

    @property public Identifier name() {
        return _name;
    }

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

public class ArrayAccess : Reference {
    private Expression _value;
    private Expression _index;
    private size_t _end;

    public this(Expression value, Expression index, size_t end) {
        _value = value;
        _index = index;
        _end = end;
    }

    @property public override size_t start() {
        return value.start;
    }

    @property public override size_t end() {
        return _end;
    }

    @property public Expression value() {
        return _value;
    }

    @property public Expression index() {
        return _index;
    }

    public override Expression map(ExpressionMapper mapper) {
        _value = _value.map(mapper);
        _index = _index.map(mapper);
        return mapper.mapArrayAccess(this);
    }

    public override immutable(TypedNode) interpret(Context context) {
        return Interpreter.INSTANCE.interpretArrayAccess(context, this);
    }

    public override string toString() {
        return format("ArrayAccess(%s[%s])", _value.toString(), _index.toString());
    }
}

public class FunctionCall : Expression, Statement {
    private Expression _value;
    private Expression[] _arguments;
    private size_t _start;
    private size_t _end;

    public this(Expression value, Expression[] arguments, size_t end) {
        this(value, arguments, value.start, end);
    }

    public this(Expression value, Expression[] arguments, size_t start, size_t end) {
        _value = value;
        _arguments = arguments;
        _start = start;
        _end = end;
    }

    @property public override size_t start() {
        return _start;
    }

    @property public override size_t end() {
        return _end;
    }

    @property public Expression value() {
        return _value;
    }

    @property public Expression[] arguments() {
        return _arguments;
    }

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
        }

        @property public Expression inner() {
            return _inner;
        }

        @property public Op operator() {
            return _operator;
        }

        @property public override size_t start() {
            return _operator.start;
        }

        @property public override size_t end() {
            return _inner.end;
        }

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

        @property public override size_t start() {
            return _left.start;
        }

        @property public override size_t end() {
            return _right.end;
        }

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
    private Type _type;
    private TypeCompareOperator _typeOperator;

    public this(Expression[] values, ValueCompareOperator[] valueOperators, Type type, TypeCompareOperator typeOperator) {
        _values = values;
        _valueOperators = valueOperators;
        _type = type;
        _typeOperator = typeOperator;
    }

    @property public Expression[] values() {
        return _values;
    }

    @property public ValueCompareOperator[] valueOperators() {
        return _valueOperators;
    }

    @property public Type type() {
        return _type;
    }

    @property public TypeCompareOperator typeOperator() {
        return _typeOperator;
    }

    @property public override size_t start() {
        return _values[0].start;
    }

    @property public override size_t end() {
        return _type is null ? _values[$ - 1].end : _type.end;
    }

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
    private Type _type;
    private TypeCompareOperator _operator;

    public this(Expression value, Type type, TypeCompareOperator operator) {
        _value = value;
        _type = type;
        _operator = operator;
    }

    @property public Expression value() {
        return _value;
    }

    @property public Type type() {
        return _type;
    }

    @property public TypeCompareOperator operator() {
        return _operator;
    }

    @property public override size_t start() {
        return _value.start;
    }

    @property public override size_t end() {
        return _type.end;
    }

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

    @property public override size_t start() {
        return _trueValue.start;
    }

    @property public override size_t end() {
        return _falseValue.end;
    }

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
