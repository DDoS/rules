module ruleslang.syntax.ast.expression;

import std.format;
import std.algorithm.iteration;

import ruleslang.syntax.dchars;
import ruleslang.syntax.token;
import ruleslang.syntax.ast.type;
import ruleslang.syntax.ast.statement;

public interface Expression {
    public string toString();
}

public class NameReference : Expression {
    private Identifier[] name;

    public this(Identifier[] name) {
        this.name = name;
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

    public override string toString() {
        return format("Initializer(%s{%s})", type.toString(), literal.values.join!", "());
    }
}

public class ContextMemberAccess : Expression {
    private Identifier name;

    public this(Identifier name) {
        this.name = name;
    }

    public override string toString() {
        return format("ContextMemberAccess(.%s)", name.getSource());
    }
}

public class MemberAccess : Expression {
    private Expression value;
    private Identifier name;

    public this(Expression value, Identifier name) {
        this.value = value;
        this.name = name;
    }

    public override string toString() {
        return format("MemberAccess(%s.%s)", value.toString(), name.getSource());
    }
}

public class ArrayAccess : Expression {
    private Expression value;
    private Expression index;

    public this(Expression value, Expression index) {
        this.value = value;
        this.index = index;
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

    public override string toString() {
        return format("FunctionCall(%s(%s))", value.toString(), arguments.join!", "());
    }
}

public template Unary(string name, Op) {
    public class Unary : Expression {
        private Expression inner;
        private Op operator;

        public this(Expression inner, Op operator) {
            this.inner = inner;
            this.operator = operator;
        }

        public override string toString() {
            return format(name ~ "(%s%s)", operator.getSource(), inner.toString());
        }
    }
}

public alias Sign = Unary!("Sign", AddOperator);
public alias BitwiseNot = Unary!("BitwiseNot", ConcatenateOperator);
public alias LogicalNot = Unary!("LogicalNot", LogicalNotOperator);

public template Binary(string name, Op) {
    public class Binary : Expression {
        private Expression left;
        private Expression right;
        private Op operator;

        public this(Expression left, Expression right, Op operator) {
            this.left = left;
            this.right = right;
            this.operator = operator;
        }

        public override string toString() {
            return format(name ~ "(%s %s %s)", left.toString(), operator.getSource(), right.toString());
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
    private Expression condition;
    private Expression trueValue;
    private Expression falseValue;

    public this(Expression condition, Expression trueValue, Expression falseValue) {
        this.condition = condition;
        this.trueValue = trueValue;
        this.falseValue = falseValue;
    }

    public override string toString() {
        return format("Conditional(%s if %s else %s)", trueValue, condition, falseValue);
    }
}
