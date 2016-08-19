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
        // Search the name spaces in order of priority, but without shadowing
        immutable(ApplicableFunction)[] functions;
        foreach (names; priority) {
            functions ~= names.getFunctions(name, argumentTypes);
        }
        if (functions.length > 0) {
            return functions.resolveOverloads();
        }
        return null;
    }
}

public immutable(Function) resolveOverloads(immutable(ApplicableFunction)[] applicables) {
    void removeB(ref immutable(ApplicableFunction)[] applicables, ref size_t a, ref size_t b) {
        applicables = applicables[0 .. b] ~ applicables[b + 1 .. $];
        if (a >= b) {
            a -= 1;
        }
        b -= 1;
    }
    // Compare each function against each other for each parameter
    assert (applicables.length > 0);
    auto parameterCount = applicables[0].func.parameterCount;
    foreach (p; 0 .. parameterCount) {
        for (size_t a = 0; a < applicables.length; a++) {
            auto applicableA = applicables[a];
            auto funcA = applicableA.func;
            for (size_t b = 0; b < applicables.length; b++) {
                auto applicableB = applicables[b];
                auto funcB = applicableB.func;
                // Don't compare the function with itself
                if (applicableA.func is applicableB.func) {
                    continue;
                }
                // Function B is less applicable than A for an argument:
                // If B requires narrowing and A does not
                bool narrowingA = applicableA.argumentConversions[p] is ConversionKind.NARROWING;
                bool narrowingB = applicableB.argumentConversions[p] is ConversionKind.NARROWING;
                if (!narrowingA && narrowingB) {
                    removeB(applicables, a, b);
                    continue;
                }
                // If A and B require narrowing and B is more specific
                auto ignored = new TypeConversionChain();
                auto argSmallerA = funcA.parameterTypes[p].convertibleTo(funcB.parameterTypes[p], ignored);
                auto argSmallerB = funcB.parameterTypes[p].convertibleTo(funcA.parameterTypes[p], ignored);
                if (narrowingA && narrowingB && !argSmallerA && argSmallerB) {
                    removeB(applicables, a, b);
                    continue;
                }
                // If A and B require widening and A is more specific
                if (!narrowingA && !narrowingB && argSmallerA && !argSmallerB) {
                    removeB(applicables, a, b);
                    continue;
                }
            }
        }
    }
    // Only one function should remain
    if (applicables.length == 1) {
        return applicables[0].func;
    }
    // Otherwise the overloads cannot be resolved
    throw new Exception(format("Cannot resolve overloads, any of the following functions are applicable:\n    %s\n",
            applicables.join!("\n    ", "a.func.toString()")));
}

public immutable struct ApplicableFunction {
    public Function func;
    public ConversionKind[] argumentConversions;

    public this(immutable(Function) func, immutable(ConversionKind)[] argumentConversions) {
        this.func = func;
        this.argumentConversions = argumentConversions;
    }
}

public interface NameSpace {
    public immutable(Field) getField(string name);
    public immutable(ApplicableFunction)[] getFunctions(string name, immutable(Type)[] argumentTypes);
}

public class ForeignNameSpace : NameSpace {
    public override immutable(Field) getField(string name) {
        return null;
    }

    public override immutable(ApplicableFunction)[] getFunctions(string name, immutable(Type)[] argumentTypes) {
        return [];
    }
}

public class ImportedNameSpace : NameSpace {
    public override immutable(Field) getField(string name) {
        return null;
    }

    public override immutable(ApplicableFunction)[] getFunctions(string name, immutable(Type)[] argumentTypes) {
        return [];
    }
}

public class ScopeNameSpace : NameSpace {
    private ScopeNameSpace parent;

    public override immutable(Field) getField(string name) {
        return null;
    }

    public override immutable(ApplicableFunction)[] getFunctions(string name, immutable(Type)[] argumentTypes) {
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

    public override immutable(ApplicableFunction)[] getFunctions(string name, immutable(Type)[] argumentTypes) {
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
        immutable(ApplicableFunction)[] functions = [];
        foreach (func; searchFunctions) {
            ConversionKind[] argumentConversions;
            if (name == func.name && func.areApplicable(argumentTypes, argumentConversions)) {
                functions ~= immutable ApplicableFunction(func, argumentConversions.assumeUnique());
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
