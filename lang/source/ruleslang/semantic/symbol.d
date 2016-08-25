module ruleslang.semantic.symbol;

import std.conv : to;

import ruleslang.semantic.type;
import ruleslang.evaluation.value;
import ruleslang.util;

public immutable interface Symbol {
    @property public string name();
    @property public string symbolicName();
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

    @property public override string symbolicName() {
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
    private string _symbolicName;
    private Type[] _parameterTypes;
    private Type _returnType;

    public this(string name, immutable(Type)[] parameterTypes, immutable Type returnType) {
        _name = name;
        _symbolicName = genSymbolicName(name, parameterTypes, returnType);
        _returnType = returnType;
        _parameterTypes = parameterTypes;
    }

    @property public override string name() {
        return _name;
    }

    @property public override string symbolicName() {
        return _symbolicName;
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

    public bool isExactly(string name, immutable(Type)[] parameterTypes) {
        return _name == name && _parameterTypes.typesEqual(parameterTypes);
    }

    public string toString() {
        return _name ~ "(" ~ _parameterTypes.join!", "() ~ ") " ~ _returnType.toString();
    }

    public bool opEquals(immutable Function other) {
        return isExactly(other.name, other.parameterTypes);
    }
}

private string genSymbolicName(string name, immutable(Type)[] parameterTypes, immutable(Type) returnType) {
    char[] buffer = [];
    buffer.reserve(256);
    // First part if the function name
    buffer ~= name;
    // Next are the argument type names
    buffer ~= '(';
    foreach (i, paramType; parameterTypes) {
        buffer ~= paramType.toString();
        if (i < parameterTypes.length - 1) {
            buffer ~= ',';
        }
    }
    buffer ~= ')';
    // Finally we append the return type
    buffer ~= returnType.toString();
    return buffer.idup;
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
