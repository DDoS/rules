module ruleslang.semantic.symbol;

import std.conv : to;
import std.exception : assumeUnique;

import ruleslang.semantic.type;
import ruleslang.util;

public immutable interface Symbol {
    @property public string name();
    @property public string symbolicName();
}

public immutable class Field : Symbol {
    private string _name;
    public Type type;

    public this(string name, immutable Type type) {
        _name = name;
        this.type = type;
    }

    @property public override string name() {
        return _name;
    }

    @property public override string symbolicName() {
        return _name;
    }

    public string toString() {
        return type.toString() ~ " " ~ _name;
    }

    public bool opEquals(immutable Field other) {
        return _name == other.name;
    }
}

public immutable class Function : Symbol {
    private string _name;
    private string _symbolicName;
    public Type[] parameterTypes;
    public Type returnType;

    public this(string name, immutable(Type)[] parameterTypes, immutable Type returnType) {
        _name = name;
        _symbolicName = genSymbolicName(name, parameterTypes, returnType);
        this.returnType = returnType;
        this.parameterTypes = parameterTypes;
    }

    @property public override string name() {
        return _name;
    }

    @property public override string symbolicName() {
        return _symbolicName;
    }

    @property ulong parameterCount() {
        return parameterTypes.length;
    }

    public bool isOverload(immutable Function other) {
        return _name == other.name && parameterTypes != other.parameterTypes;
    }

    public bool areApplicable(immutable(Type)[] argumentTypes, out ConversionKind[] argumentConversions) {
        if (parameterTypes.length != argumentTypes.length) {
            return false;
        }
        argumentConversions = new ConversionKind[argumentTypes.length];
        foreach (i, argType; argumentTypes) {
            auto paramType = parameterTypes[i];
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
        return _name == name && this.parameterTypes.typesEqual(parameterTypes);
    }

    public string toString() {
        return _name ~ "(" ~ parameterTypes.join!", "() ~ ") " ~ returnType.toString();
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
        "^^": "opLogicalXor",
        "~": "opConcatenate",
        "..": "opRange"
    ];
    BINARY_OPERATOR_TO_FUNCTION = binaryOperatorToFunction.assumeUnique();
}
