module ruleslang.semantic.context;

import std.exception : assumeUnique;
import std.meta : AliasSeq;
import std.format : format;

import ruleslang.semantic.type;
import ruleslang.semantic.symbol;
import ruleslang.evaluation.value;
import ruleslang.util;

public class Context {
    private ForeignNameSpace foreignNames;
    private ImportedNameSpace importedNames;
    private ScopeNameSpace scopeNames;
    private IntrinsicNameSpace intrisicNames;
    private NameSpace[] priority;

    public this() {
        foreignNames = new ForeignNameSpace();
        importedNames = new ImportedNameSpace();
        scopeNames = new ScopeNameSpace();
        intrisicNames = new IntrinsicNameSpace();
        priority = [
            cast(NameSpace) intrisicNames, cast(NameSpace) scopeNames, cast(NameSpace) importedNames
        ];
    }

    public immutable(Field) resolveField(string name) {
        // Search the name spaces in order of priority
        // Allowing higher priority ones to shadow the others
        // TODO: allow shawdowing?
        foreach (names; priority) {
            auto field = names.getField(name);
            if (field !is null) {
                return field;
            }
        }
        return null;
    }

    public immutable(Function) resolveFunction(string name, immutable(Type)[] argumentTypes) {
        // Search the name spaces in order of priority, but without shadowing. Start with convertible functions
        auto convertibleFunction = resolveFunction!true(name, argumentTypes);
        if (convertibleFunction !is null) {
            return convertibleFunction;
        }
        // Then, if the agument types are literals, try specializable functions
        foreach (type; argumentTypes) {
            if (cast(LiteralType) type is null) {
                return convertibleFunction;
            }
        }
        return resolveFunction!false(name, cast(immutable(LiteralType)[]) argumentTypes);
    }

    private immutable(Function) resolveFunction(bool convertible, T : Type)(string name, immutable(T)[] argumentTypes) {
        immutable(Function)[] functions;
        foreach (names; priority) {
            functions ~= mixin("names." ~ (convertible ? "convertible" : "specializable") ~ "Functions(name, argumentTypes)");
        }
        if (functions.length > 0) {
            return functions.resolveOverloads!convertible();
        }
        return null;
    }
}

private immutable(Function) resolveOverloads(bool more)(immutable(Function)[] functions) {
    for (size_t a = 0; a < functions.length; a++) {
        auto funcA = functions[a];
        for (size_t b = 0; b < functions.length; b++) {
            auto funcB = functions[b];
            // Don't compare the function with itself
            if (funcA is funcB) {
                continue;
            }
            // Remove the least specific functions
            if (funcA.testSpecificity!more(funcB)) {
                functions = functions[0 .. b] ~ functions[b + 1 .. $];
                b -= 1;
            }
        }
    }
    // Only one function should remain
    if (functions.length == 1) {
        return functions[0];
    }
    // Otherwise the overloads cannot be resolved
    return null;
}

public interface NameSpace {
    public immutable(Field) getField(string name);
    public immutable(Function)[] convertibleFunctions(string name, immutable(Type)[] argumentTypes);
    public immutable(Function)[] specializableFunctions(string name, immutable(LiteralType)[] argumentTypes);
}

public class ForeignNameSpace : NameSpace {
    public override immutable(Field) getField(string name) {
        return null;
    }

    public override immutable(Function)[] convertibleFunctions(string name, immutable(Type)[] argumentTypes) {
        return [];
    }

    public override immutable(Function)[] specializableFunctions(string name, immutable(LiteralType)[] argumentTypes) {
        return [];
    }
}

public class ImportedNameSpace : NameSpace {
    public override immutable(Field) getField(string name) {
        return null;
    }

    public override immutable(Function)[] convertibleFunctions(string name, immutable(Type)[] argumentTypes) {
        return [];
    }

    public override immutable(Function)[] specializableFunctions(string name, immutable(LiteralType)[] argumentTypes) {
        return [];
    }
}

public class ScopeNameSpace : NameSpace {
    private ScopeNameSpace parent;

    public override immutable(Field) getField(string name) {
        return null;
    }

    public override immutable(Function)[] convertibleFunctions(string name, immutable(Type)[] argumentTypes) {
        return [];
    }

    public override immutable(Function)[] specializableFunctions(string name, immutable(LiteralType)[] argumentTypes) {
        return [];
    }
}

public enum OperatorFunction : string {
    NEGATE_FUNCTION = "opNegate",
    REAFFIRM_FUNCTION = "opReaffirm",
    LOGICAL_NOT_FUNCTION = "opLogicalNot",
    BITWISE_NOT_FUNCTION = "opBitwiseNot",
    EXPONENT_FUNCTION = "opExponent",
    MULTIPLY_FUNCTION = "opMultiply",
    DIVIDE_FUNCTION = "opDivide",
    REMAINDER_FUNCTION = "opRemainder",
    ADD_FUNCTION = "opAdd",
    SUBTRACT_FUNCTION = "opSubtract",
    LEFT_SHIFT_FUNCTION = "opLeftShift",
    ARITHMETIC_RIGHT_SHIFT_FUNCTION = "opArithmeticRightShift",
    LOGICAL_RIGHT_SHIFT_FUNCTION = "opLogicalRightShift",
    EQUALS_FUNCTION = "opEquals",
    NOT_EQUALS_FUNCTION = "opNotEquals",
    LESSER_THAN_FUNCTION = "opLesserThan",
    GREATER_THAN_FUNCTION = "opGreaterThan",
    LESSER_OR_EQUAL_TO_FUNCTION = "opLesserOrEqualTo",
    GREATER_OR_EQUAL_TO_FUNCTION = "opGreaterOrEqualTo",
    BITWISE_AND_FUNCTION = "opBitwiseAnd",
    BITWISE_XOR_FUNCTION = "opBitwiseXor",
    BITWISE_OR_FUNCTION = "opBitwiseOr",
    LOGICAL_AND_FUNCTION = "opLogicalAnd",
    LOGICAL_XOR_FUNCTION = "opLogicalXor",
    LOGICAL_OR_FUNCTION = "opLogicalOr",
    CONCATENATE_FUNCTION = "opConcatenate",
    RANGE_FUNCTION = "opRange",
    CONDITIONAL_FUNCTION = "opConditional"
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

public class IntrinsicNameSpace : NameSpace {
    private static immutable immutable(Function)[] unaryOperators;
    private static immutable immutable(Function)[] binaryOperators;
    private static immutable immutable(Function)[] ternaryOperators;

    public static this() {
        alias IntegerTypes = AliasSeq!(byte, ubyte, short, ushort, int, uint, long, ulong);
        alias NumericTypes = AliasSeq!(IntegerTypes, float, double);
        alias AllTypes = AliasSeq!(bool, NumericTypes);
        // Build the intrinsic unary and binary function lists
        immutable(Function)[] functions = [];
        // Operator unary -
        functions ~= genUnaryFunctions!(OperatorFunction.NEGATE_FUNCTION, ToSigned, NumericTypes);
        // Operator unary +
        functions ~= genUnaryFunctions!(OperatorFunction.REAFFIRM_FUNCTION, Same, NumericTypes);
        // Operator unary !
        functions ~= genUnaryFunctions!(OperatorFunction.LOGICAL_NOT_FUNCTION, Same, bool);
        // Operator unary ~
        functions ~= genUnaryFunctions!(OperatorFunction.BITWISE_NOT_FUNCTION, Same, IntegerTypes);
        unaryOperators = functions.idup;
        functions.length = 0;
        // Operators binary **, *, /, %, +, -
        functions ~= genBinaryFunctions!(OperatorFunction.EXPONENT_FUNCTION, Same, Same, NumericTypes)();
        functions ~= genBinaryFunctions!(OperatorFunction.MULTIPLY_FUNCTION, Same, Same, NumericTypes)();
        functions ~= genBinaryFunctions!(OperatorFunction.DIVIDE_FUNCTION, Same, Same, NumericTypes)();
        functions ~= genBinaryFunctions!(OperatorFunction.REMAINDER_FUNCTION, Same, Same, NumericTypes)();
        functions ~= genBinaryFunctions!(OperatorFunction.ADD_FUNCTION, Same, Same, NumericTypes)();
        functions ~= genBinaryFunctions!(OperatorFunction.SUBTRACT_FUNCTION, Same, Same, NumericTypes)();
        // Operators binary <<, >>, >>>
        functions ~= genBinaryFunctions!(OperatorFunction.LEFT_SHIFT_FUNCTION, Constant!ulong, Same, IntegerTypes)();
        functions ~= genBinaryFunctions!(OperatorFunction.ARITHMETIC_RIGHT_SHIFT_FUNCTION, Constant!ulong, Same, IntegerTypes)();
        functions ~= genBinaryFunctions!(OperatorFunction.LOGICAL_RIGHT_SHIFT_FUNCTION, Constant!ulong, Same, IntegerTypes)();
        // Operators binary ==, !=, <, >, <=, >=
        functions ~= genBinaryFunctions!(OperatorFunction.EQUALS_FUNCTION, Same, Constant!bool, AllTypes)();
        functions ~= genBinaryFunctions!(OperatorFunction.NOT_EQUALS_FUNCTION, Same, Constant!bool, AllTypes)();
        functions ~= genBinaryFunctions!(OperatorFunction.LESSER_THAN_FUNCTION, Same, Constant!bool, AllTypes)();
        functions ~= genBinaryFunctions!(OperatorFunction.GREATER_THAN_FUNCTION, Same, Constant!bool, AllTypes)();
        functions ~= genBinaryFunctions!(OperatorFunction.LESSER_OR_EQUAL_TO_FUNCTION, Same, Constant!bool, AllTypes)();
        functions ~= genBinaryFunctions!(OperatorFunction.GREATER_OR_EQUAL_TO_FUNCTION, Same, Constant!bool, AllTypes)();
        // Operators binary &, ^, |
        functions ~= genBinaryFunctions!(OperatorFunction.BITWISE_AND_FUNCTION, Same, Same, IntegerTypes)();
        functions ~= genBinaryFunctions!(OperatorFunction.BITWISE_XOR_FUNCTION, Same, Same, IntegerTypes)();
        functions ~= genBinaryFunctions!(OperatorFunction.BITWISE_OR_FUNCTION, Same, Same, IntegerTypes)();
        // Operators binary &&, ^^, ||
        functions ~= genBinaryFunctions!(OperatorFunction.LOGICAL_AND_FUNCTION, Same, Same, bool)();
        functions ~= genBinaryFunctions!(OperatorFunction.LOGICAL_XOR_FUNCTION, Same, Same, bool)();
        functions ~= genBinaryFunctions!(OperatorFunction.LOGICAL_OR_FUNCTION, Same, Same, bool)();
        // TODO: operators ~, ..
        binaryOperators = functions.idup;
        functions.length = 0;
        // Operators ternary ... if ... else ...
        functions ~= genTernaryFunctions!(OperatorFunction.CONDITIONAL_FUNCTION, Constant!bool, Same, Same, AllTypes)();
        ternaryOperators = functions.idup;
    }

    public override immutable(Field) getField(string name) {
        return null;
    }

    public override immutable(Function)[] convertibleFunctions(string name, immutable(Type)[] argumentTypes) {
        return applicableFunctions!"areConvertible"(name, argumentTypes);
    }

    public override immutable(Function)[] specializableFunctions(string name, immutable(LiteralType)[] argumentTypes) {
        return applicableFunctions!"areSpecializable"(name, argumentTypes);
    }

    private immutable(Function)[] applicableFunctions(string test, T : Type)(string name, immutable(T)[] argumentTypes) {
        if (argumentTypes.length <= 0 || argumentTypes.length > 3) {
            return [];
        }
        // Search for functions that can be applied to the argument types
        immutable(Function)[] searchFunctions;
        final switch (argumentTypes.length) {
            case 1:
                searchFunctions = unaryOperators;
                break;
            case 2:
                searchFunctions = binaryOperators;
                break;
            case 3:
                searchFunctions = ternaryOperators;
                break;
        }
        immutable(Function)[] functions = [];
        foreach (func; searchFunctions) {
            if (name == func.name && mixin("func." ~ test ~ "(argumentTypes)")) {
                functions ~= func;
            }
        }
        return functions;
    }
}

private alias Same(T) = T;

private template Constant(C) {
    private alias Constant(T) = C;
}

private template ToSigned(T) {
    static if (is(T == ubyte) || is(T == byte)) {
        private alias ToSigned = byte;
    } else static if (is(T == ushort) || is(T == short)) {
        private alias ToSigned = short;
    } else static if (is(T == uint) || is(T == int)) {
        private alias ToSigned = int;
    } else static if (is(T == ulong) || is(T == long)) {
        private alias ToSigned = long;
    } else static if (is(T == float)) {
        private alias ToSigned = float;
    } else static if (is(T == double)) {
        private alias ToSigned = double;
    } else {
        static assert (0);
    }
}

private immutable(Function)[] genUnaryFunctions(OperatorFunction func,
        alias ReturnFromInner, Inner, Inners...)() {
    alias Return = ReturnFromInner!Inner;
    auto innerType = atomicTypeFor!Inner();
    auto returnType = atomicTypeFor!Return();
    auto funcs = [new immutable Function(func, [innerType], returnType)];
    static if (Inners.length > 0) {
        funcs ~= genUnaryFunctions!(func, ReturnFromInner, Inners)();
    }
    return funcs;
}

private immutable(Function)[] genBinaryFunctions(OperatorFunction func,
        alias RightFromLeft, alias ReturnFromLeft, Left, Lefts...)() {
    alias Right = RightFromLeft!Left;
    alias Return = ReturnFromLeft!Left;
    auto leftType = atomicTypeFor!Left();
    auto rightType = atomicTypeFor!Right();
    auto returnType = atomicTypeFor!Return();
    auto funcs = [new immutable Function(func, [leftType, rightType], returnType)];
    static if (Lefts.length > 0) {
        funcs ~= genBinaryFunctions!(func, RightFromLeft, ReturnFromLeft, Lefts)();
    }
    return funcs;
}

private immutable(Function)[] genTernaryFunctions(OperatorFunction func,
        alias LeftFromMiddle, alias RightFromMiddle, alias ReturnFromMiddle, Middle, Middles...)() {
    alias Left = LeftFromMiddle!Middle;
    alias Right = RightFromMiddle!Middle;
    alias Return = ReturnFromMiddle!Middle;
    auto leftType = atomicTypeFor!Left();
    auto middleType = atomicTypeFor!Middle();
    auto rightType = atomicTypeFor!Right();
    auto returnType = atomicTypeFor!Return();
    auto funcs = [new immutable Function(func, [leftType, middleType, rightType], returnType)];
    static if (Middles.length > 0) {
        funcs ~= genTernaryFunctions!(func, LeftFromMiddle, RightFromMiddle, ReturnFromMiddle, Middles)();
    }
    return funcs;
}

private immutable(AtomicType) atomicTypeFor(T)() {
    static if (is(T == bool)) {
        return AtomicType.BOOL;
    } else static if (is(T == byte)) {
        return AtomicType.SINT8;
    } else static if (is(T == ubyte)) {
        return AtomicType.UINT8;
    } else static if (is(T == short)) {
        return AtomicType.SINT16;
    } else static if (is(T == ushort)) {
        return AtomicType.UINT16;
    } else static if (is(T == int)) {
        return AtomicType.SINT32;
    } else static if (is(T == uint)) {
        return AtomicType.UINT32;
    } else static if (is(T == long)) {
        return AtomicType.SINT64;
    } else static if (is(T == ulong)) {
        return AtomicType.UINT64;
    } else static if (is(T == float)) {
        return AtomicType.FP32;
    } else static if (is(T == double)) {
        return AtomicType.FP64;
    } else {
        static assert (0);
    }
}

private enum string[string] FUNCTION_TO_DLANG_OPERATOR = [
    "opNegate": "-$0",
    "opReaffirm": "+$0",
    "opLogicalNot": "!$0",
    "opBitwiseNot": "~$0",
    "opExponent": "$0 ^^ $1",
    "opMultiply": "$0 * $1",
    "opDivide": "$0 / $1",
    "opRemainder": "$0 % $1",
    "opAdd": "$0 + $1",
    "opSubtract": "$0 - $1",
    "opLeftShift": "$0 << $1",
    "opArithmeticRightShift": "$0 >> $1",
    "opLogicalRightShift": "$0 >>> $1",
    "opEquals": "$0 == $1",
    "opNotEquals": "$0 != $1",
    "opLesserThan": "$0 < $1",
    "opGreaterThan": "$0 > $1",
    "opLesserOrEqualTo": "$0 <= $1",
    "opGreaterOrEqualTo": "$0 >= $1",
    "opBitwiseAnd": "$0 & $1",
    "opBitwiseXor": "$0 ^ $1",
    "opBitwiseOr": "$0 | $1",
    "opLogicalAnd": "$0 && $1",
    "opLogicalXor": "$0 ^ $1",
    "opLogicalOr": "$0 || $1",
    "opConcatenate": "$0 ~ $1",
    "opRange": "$0.p_range($1)",
    "opConditional": "$0 ? $1 : $2"
];

public alias FunctionImpl = immutable(Value) function(immutable(Value)[]);

private FunctionImpl genUnaryOperatorImpl(OperatorFunction func, Inner, Return)() {
    FunctionImpl implementation = (arguments) {
        assert (arguments.length == 1);
        enum op = FUNCTION_TO_DLANG_OPERATOR[func].positionalReplace("arguments[0].as!Inner");
        return valueOf(cast(Return) mixin("(" ~ op ~ ")"));
    };
    return implementation;
}

private FunctionImpl genBinaryOperatorImpl(OperatorFunction func, Left, Right, Return)() {
    FunctionImpl implementation = (arguments) {
        assert (arguments.length == 2);
        enum op = FUNCTION_TO_DLANG_OPERATOR[func].positionalReplace("arguments[0].as!Left", "arguments[1].as!Right");
        return valueOf(cast(Return) mixin("(" ~ op ~ ")"));
    };
    return implementation;
}

private FunctionImpl genTernaryOperatorImpl(OperatorFunction func, Left, Middle, Right, Return)() {
    FunctionImpl implementation = (arguments) {
        assert (arguments.length == 3);
        enum op = FUNCTION_TO_DLANG_OPERATOR[func].positionalReplace("arguments[0].as!Left", "arguments[1].as!Middle",
                "arguments[2].as!Right");
        return valueOf(cast(Return) mixin("(" ~ op ~ ")"));
    };
    return implementation;
}
