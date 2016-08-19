module ruleslang.semantic.symbol;

import std.conv : to;

import ruleslang.semantic.type;
import ruleslang.evaluation.value;
import ruleslang.util;

public immutable interface Symbol {
    @property public string name();
}

public immutable class Field : Symbol {
    private string _name;
    private Type _type;

    public this(string name, immutable Type type) {
        _name = name;
        _type = type;
    }

    @property public override string name() {
        return _name;
    }

    @property public immutable(Type) type() {
        return _type;
    }

    public string toString() {
        return _type.toString() ~ " " ~ _name;
    }

    public bool opEquals(immutable Field other) {
        return _name == other.name;
    }
}

public immutable class Function : Symbol {
    private string _name;
    private Type[] _parameterTypes;
    private Type _returnType;

    public this(string name, immutable(Type)[] parameterTypes, immutable Type returnType) {
        _name = name;
        _returnType = returnType;
        _parameterTypes = parameterTypes;
    }

    @property public override string name() {
        return _name;
    }

    @property public immutable(Type[]) parameterTypes() {
        return _parameterTypes;
    }

    @property ulong parameterCount() {
        return _parameterTypes.length;
    }

    @property public immutable(Type) returnType() {
        return _returnType;
    }

    public bool isOverload(immutable Function other) {
        return _name == other.name && _parameterTypes != other.parameterTypes;
    }

    public bool areApplicable(immutable(Type)[] argumentTypes, out ConversionKind[] argumentConversions) {
        if (_parameterTypes.length != argumentTypes.length) {
            return false;
        }
        argumentConversions = new ConversionKind[argumentTypes.length];
        foreach (i, argType; argumentTypes) {
            auto paramType = _parameterTypes[i];
            bool applicable;
            auto chain = new TypeConversionChain();
            auto literalArgType = cast(immutable LiteralType) argType;
            if (literalArgType !is null) {
                applicable = literalArgType.specializableTo(paramType, chain);
            } else {
                applicable = argType.convertibleTo(paramType, chain);
            }
            if (!applicable) {
                return false;
            }
            argumentConversions[i] = chain.conversionKind();
        }
        return true;
    }

    public string toString() {
        return _name ~ "(" ~ _parameterTypes.join!", "() ~ ") " ~ _returnType.toString();
    }

    public bool opEquals(immutable Function other) {
        return _name == other.name && _parameterTypes == other.parameterTypes;
    }
}

public immutable string[string] UNARY_OPERATOR_TO_FUNCTION;
public immutable string[string] BINARY_OPERATOR_TO_FUNCTION;

public static this() {
    string[string] unaryOperatorsToFunction = [
        "-": "opNegate",
        "+": "opReaffirm",
        "!": "opLogicalNot",
        "~": "opBitwiseNot",
    ];
    UNARY_OPERATOR_TO_FUNCTION = unaryOperatorsToFunction.assumeUnique();
    string[string] binaryOperatorToFunction = [
        "**": "opExponent",
        "*": "opMultiply",
        "/": "opDivide",
        "%": "opRemainder",
        "+": "opAdd",
        "-": "opSubtract",
        "<<": "opLeftShift",
        ">>": "opArithmeticRightShift",
        ">>>": "opLogicalRightShift",
        "==": "opEquals",
        "!=": "opNotEquals",
        "<": "opLesserThan",
        ">": "opGreaterThan",
        "<=": "opLesserOrEqualTo",
        ">=": "opGreaterOrEqualTo",
        "&": "opBitwiseAnd",
        "^": "opBitwiseXor",
        "|": "opBitwiseOr",
        "&&": "opLogicalAnd",
        "^^": "opLogicalXor",
        "||": "opLogicalOr",
        "~": "opConcatenate",
        "..": "opRange"
    ];
    BINARY_OPERATOR_TO_FUNCTION = binaryOperatorToFunction.assumeUnique();
}
