module ruleslang.semantic.context;

import std.exception : assumeUnique;
import std.meta : AliasSeq;
import std.format : format;

import ruleslang.semantic.type;
import ruleslang.semantic.symbol;
import ruleslang.evaluation.runtime;
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
    auto wideningOnly = applicables.removeLesser!false();
    // Only one function should remain
    if (wideningOnly.length == 1) {
        return wideningOnly[0].func;
    }
    // Otherwise retry, but allow narrowing too
    auto withNarrowing = applicables.removeLesser!true();
    if (withNarrowing.length == 1) {
        return withNarrowing[0].func;
    }
    // Otherwise the overloads cannot be resolved
    throw new Exception(format("Cannot resolve overloads, any of the following functions are applicable:\n    %s\n",
            withNarrowing.join!("\n    ", "a.func.toString()")));
}

private immutable(ApplicableFunction)[] removeLesser(bool narrowing)(immutable(ApplicableFunction)[] applicables) {
    // Compare each function against each other
    assert (applicables.length > 0);
    auto parameterCount = applicables[0].func.parameterCount;
    for (size_t a = 0; a < applicables.length; a++) {
        auto applicableA = applicables[a];
        for (size_t b = 0; b < applicables.length; b++) {
            auto applicableB = applicables[b];
            // Remove B if A is more applicable
            if (applicableA.isMoreApplicable!narrowing(applicableB)) {
                applicables = applicables[0 .. b] ~ applicables[b + 1 .. $];
                if (a >= b) {
                    a -= 1;
                }
                b -= 1;
            }
        }
    }
    return applicables;
}

public immutable struct ApplicableFunction {
    public Function func;
    public ConversionKind[] argumentConversions;

    public this(immutable(Function) func, immutable(ConversionKind)[] argumentConversions) {
        this.func = func;
        this.argumentConversions = argumentConversions;
    }

    public ConversionKind conversionKind() {
        foreach (conversion; argumentConversions) {
            if (conversion is ConversionKind.NARROWING) {
                return ConversionKind.NARROWING;
            }
        }
        return ConversionKind.WIDENING;
    }

    public bool isMoreApplicable(bool narrowing)(immutable ApplicableFunction other) {
        assert (func.parameterCount == other.func.parameterCount);
        static if (!narrowing) {
            if (conversionKind() is ConversionKind.NARROWING) {
                return false;
            }
        }
        // This function is more applicable if any of the other parameters is lesser
        foreach (i; 0 .. func.parameterCount) {
            if (isLesser(other.func.parameterTypes[i], other.argumentConversions[i],
                    func.parameterTypes[i], argumentConversions[i])) {
                return true;
            }
        }
        return false;
    }

    private static bool isLesser(immutable Type paramA, ConversionKind convA, immutable Type paramB, ConversionKind convB) {
        // Parameter A is less applicable than B for an argument:
        // If A requires narrowing and B does not
        bool narrowingA = convA is ConversionKind.NARROWING;
        bool narrowingB = convB is ConversionKind.NARROWING;
        if (narrowingA && !narrowingB) {
            return true;
        }
        // If A and B require narrowing and A is more specific
        auto ignored = new TypeConversionChain();
        auto argSmallerA = paramA.convertibleTo(paramB, ignored);
        auto argSmallerB = paramB.convertibleTo(paramA, ignored);
        if (narrowingA && narrowingB && argSmallerA && !argSmallerB) {
            return true;
        }
        // If A and B require widening and B is more specific
        return !narrowingA && !narrowingB && !argSmallerA && argSmallerB;
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

public immutable struct IntrinsicFunction {
    public Function func;
    public FunctionImpl impl;

    public this(immutable Function func, immutable FunctionImpl impl) {
        this.func = func;
        this.impl = impl;
    }
}

public class IntrinsicNameSpace : NameSpace {
    private alias IntrinsicFunctions = immutable IntrinsicFunction[];
    private static immutable IntrinsicFunctions[string] unaryOperators;
    private static immutable IntrinsicFunctions[string] binaryOperators;
    private static immutable IntrinsicFunctions[string] ternaryOperators;
    public static immutable FunctionImpl[string] FUNCTION_IMPLEMENTATIONS;

    public static this() {
        string getName(immutable IntrinsicFunction intrinsic) {
            return intrinsic.func.name;
        }
        // The list of dlang types equivalent to the plang ones
        alias IntegerTypes = AliasSeq!(byte, ubyte, short, ushort, int, uint, long, ulong);
        alias NumericTypes = AliasSeq!(IntegerTypes, float, double);
        alias AllTypes = AliasSeq!(bool, NumericTypes);
        // Build the intrinsic unary function list
        immutable(IntrinsicFunction)[] unaryFunctions = [];
        // Operator unary -
        unaryFunctions ~= genUnaryFunctions!(OperatorFunction.NEGATE_FUNCTION, ToSigned, NumericTypes);
        // Operator unary +
        unaryFunctions ~= genUnaryFunctions!(OperatorFunction.REAFFIRM_FUNCTION, Same, NumericTypes);
        // Operator unary !
        unaryFunctions ~= genUnaryFunctions!(OperatorFunction.LOGICAL_NOT_FUNCTION, Same, bool);
        // Operator unary ~
        unaryFunctions ~= genUnaryFunctions!(OperatorFunction.BITWISE_NOT_FUNCTION, Same, IntegerTypes);
        // Numeric cast functions
        unaryFunctions ~= genCastFunctions!NumericTypes();
        auto assocUnaryFunctions = unaryFunctions.associateArrays!getName();
        unaryOperators = assocUnaryFunctions.assumeUnique();
        // Build the intrinsic binary function list
        immutable(IntrinsicFunction)[] binaryFunctions = [];
        // Operators binary **, *, /, %, +, -
        binaryFunctions ~= genBinaryFunctions!(OperatorFunction.EXPONENT_FUNCTION, Same, Same, NumericTypes)();
        binaryFunctions ~= genBinaryFunctions!(OperatorFunction.MULTIPLY_FUNCTION, Same, Same, NumericTypes)();
        binaryFunctions ~= genBinaryFunctions!(OperatorFunction.DIVIDE_FUNCTION, Same, Same, NumericTypes)();
        binaryFunctions ~= genBinaryFunctions!(OperatorFunction.REMAINDER_FUNCTION, Same, Same, NumericTypes)();
        binaryFunctions ~= genBinaryFunctions!(OperatorFunction.ADD_FUNCTION, Same, Same, NumericTypes)();
        binaryFunctions ~= genBinaryFunctions!(OperatorFunction.SUBTRACT_FUNCTION, Same, Same, NumericTypes)();
        // Operators binary <<, >>, >>>
        binaryFunctions ~= genBinaryFunctions!(OperatorFunction.LEFT_SHIFT_FUNCTION, Constant!ulong, Same, IntegerTypes)();
        binaryFunctions ~= genBinaryFunctions!(OperatorFunction.ARITHMETIC_RIGHT_SHIFT_FUNCTION,
                Constant!ulong, Same, IntegerTypes)();
        binaryFunctions ~= genBinaryFunctions!(OperatorFunction.LOGICAL_RIGHT_SHIFT_FUNCTION,
                Constant!ulong, Same, IntegerTypes)();
        // Operators binary ==, !=, <, >, <=, >=
        binaryFunctions ~= genBinaryFunctions!(OperatorFunction.EQUALS_FUNCTION, Same, Constant!bool, AllTypes)();
        binaryFunctions ~= genBinaryFunctions!(OperatorFunction.NOT_EQUALS_FUNCTION, Same, Constant!bool, AllTypes)();
        binaryFunctions ~= genBinaryFunctions!(OperatorFunction.LESSER_THAN_FUNCTION, Same, Constant!bool, AllTypes)();
        binaryFunctions ~= genBinaryFunctions!(OperatorFunction.GREATER_THAN_FUNCTION, Same, Constant!bool, AllTypes)();
        binaryFunctions ~= genBinaryFunctions!(OperatorFunction.LESSER_OR_EQUAL_TO_FUNCTION, Same, Constant!bool, AllTypes)();
        binaryFunctions ~= genBinaryFunctions!(OperatorFunction.GREATER_OR_EQUAL_TO_FUNCTION, Same, Constant!bool, AllTypes)();
        // Operators binary &, ^, |
        binaryFunctions ~= genBinaryFunctions!(OperatorFunction.BITWISE_AND_FUNCTION, Same, Same, IntegerTypes)();
        binaryFunctions ~= genBinaryFunctions!(OperatorFunction.BITWISE_XOR_FUNCTION, Same, Same, IntegerTypes)();
        binaryFunctions ~= genBinaryFunctions!(OperatorFunction.BITWISE_OR_FUNCTION, Same, Same, IntegerTypes)();
        // Operators binary &&, ^^, ||
        binaryFunctions ~= genBinaryFunctions!(OperatorFunction.LOGICAL_AND_FUNCTION, Same, Same, bool)();
        binaryFunctions ~= genBinaryFunctions!(OperatorFunction.LOGICAL_XOR_FUNCTION, Same, Same, bool)();
        binaryFunctions ~= genBinaryFunctions!(OperatorFunction.LOGICAL_OR_FUNCTION, Same, Same, bool)();
        // TODO: operators ~, ..
        auto assocBinaryFunctions = binaryFunctions.associateArrays!getName();
        binaryOperators = assocBinaryFunctions.assumeUnique();
        // Build the intrinsic unary function list
        immutable(IntrinsicFunction)[] ternaryFunctions = [];
        // Operators ternary ... if ... else ...
        ternaryFunctions ~= genTernaryFunctions!(OperatorFunction.CONDITIONAL_FUNCTION, Constant!bool, Same, Same, AllTypes)();
        auto assocTernaryFunctions = ternaryFunctions.associateArrays!getName();
        ternaryOperators = assocTernaryFunctions.assumeUnique();
        // Create the function implementation lookup table
        void addNoReplace(ref FunctionImpl[string] array, IntrinsicFunction intrinsic) {
            auto name = intrinsic.func.symbolicName;
            auto already = name in array;
            assert (already is null);
            array[name] = intrinsic.impl;
        }
        FunctionImpl[string] functionImpls;
        foreach (intrinsic; unaryFunctions) {
            addNoReplace(functionImpls, intrinsic);
        }
        foreach (intrinsic; binaryFunctions) {
            addNoReplace(functionImpls, intrinsic);
        }
        foreach (intrinsic; ternaryFunctions) {
            addNoReplace(functionImpls, intrinsic);
        }
        FUNCTION_IMPLEMENTATIONS = functionImpls.assumeUnique();
    }

    private this() {
    }

    public override immutable(Field) getField(string name) const {
        return null;
    }

    public override immutable(ApplicableFunction)[] getFunctions(string name, immutable(Type)[] argumentTypes) {
        if (argumentTypes.length <= 0 || argumentTypes.length > 3) {
            return [];
        }
        // Search for functions that can be applied to the argument types
        IntrinsicFunctions searchFunctions = getFunctions(name, argumentTypes.length);
        immutable(ApplicableFunction)[] functions = [];
        foreach (intrinsic; searchFunctions) {
            auto func = intrinsic.func;
            ConversionKind[] argumentConversions;
            if (func.areApplicable(argumentTypes, argumentConversions)) {
                functions ~= immutable ApplicableFunction(func, argumentConversions.assumeUnique());
            }
        }
        return functions;
    }

    public static immutable(Function) getExactFunction(string name, immutable(Type)[] parameterTypes) {
        IntrinsicFunctions searchFunctions = getFunctions(name, parameterTypes.length);
        foreach (intrinsic; searchFunctions) {
            auto func = intrinsic.func;
            if (func.isExactly(name, parameterTypes)) {
                return func;
            }
        }
        return null;
    }

    private static IntrinsicFunctions getFunctions(string name, size_t argumentCount) {
        IntrinsicFunctions* searchFunctions;
        switch (argumentCount) {
            case 1:
                searchFunctions = name in unaryOperators;
                break;
            case 2:
                searchFunctions = name in binaryOperators;
                break;
            case 3:
                searchFunctions = name in ternaryOperators;
                break;
            default:
                searchFunctions = null;
        }
        if (searchFunctions == null) {
            return [];
        }
        return *searchFunctions;
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

private immutable(IntrinsicFunction)[] genUnaryFunctions(OperatorFunction op,
        alias ReturnFromInner, Inner, Inners...)() {
    alias Return = ReturnFromInner!Inner;
    auto innerType = atomicTypeFor!Inner();
    auto returnType = atomicTypeFor!Return();
    auto func = new immutable Function(op, [innerType], returnType);
    auto impl = genUnaryOperatorImpl!(op, Inner, Return);
    auto funcs = [immutable IntrinsicFunction(func, impl)];
    static if (Inners.length > 0) {
        funcs ~= genUnaryFunctions!(op, ReturnFromInner, Inners)();
    }
    return funcs;
}

private immutable(IntrinsicFunction)[] genCastFunctions(Types...)() {
    immutable(IntrinsicFunction)[] genCasts(To, From, Froms...)() {
        auto fromType = atomicTypeFor!From();
        auto toType = atomicTypeFor!To();
        auto func = new immutable Function(toType.toString(), [fromType], toType);
        auto impl = genCastImpl!(From, To);
        auto funcs = [immutable IntrinsicFunction(func, impl)];
        static if (Froms.length > 0) {
            funcs ~= genCasts!(To, Froms);
        }
        return funcs;
    }

    immutable(IntrinsicFunction)[] genCastsToTypes(To, Tos...)() {
        auto funcs = genCasts!(To, Types);
        static if (Tos.length > 0) {
            funcs ~= genCastsToTypes!Tos();
        }
        return funcs;
    }

    return genCastsToTypes!Types;
}

private immutable(IntrinsicFunction)[] genBinaryFunctions(OperatorFunction op,
        alias RightFromLeft, alias ReturnFromLeft, Left, Lefts...)() {
    alias Right = RightFromLeft!Left;
    alias Return = ReturnFromLeft!Left;
    auto leftType = atomicTypeFor!Left();
    auto rightType = atomicTypeFor!Right();
    auto returnType = atomicTypeFor!Return();
    auto func = new immutable Function(op, [leftType, rightType], returnType);
    auto impl = genBinaryOperatorImpl!(op, Left, Right, Return);
    auto funcs = [immutable IntrinsicFunction(func, impl)];
    static if (Lefts.length > 0) {
        funcs ~= genBinaryFunctions!(op, RightFromLeft, ReturnFromLeft, Lefts)();
    }
    return funcs;
}

private immutable(IntrinsicFunction)[] genTernaryFunctions(OperatorFunction op,
        alias LeftFromMiddle, alias RightFromMiddle, alias ReturnFromMiddle, Middle, Middles...)() {
    alias Left = LeftFromMiddle!Middle;
    alias Right = RightFromMiddle!Middle;
    alias Return = ReturnFromMiddle!Middle;
    auto leftType = atomicTypeFor!Left();
    auto middleType = atomicTypeFor!Middle();
    auto rightType = atomicTypeFor!Right();
    auto returnType = atomicTypeFor!Return();
    auto func = new immutable Function(op, [leftType, middleType, rightType], returnType);
    auto impl = genTernaryOperatorImpl!(op, Left, Middle, Right, Return);
    auto funcs = [immutable IntrinsicFunction(func, impl)];
    static if (Middles.length > 0) {
        funcs ~= genTernaryFunctions!(op, LeftFromMiddle, RightFromMiddle, ReturnFromMiddle, Middles)();
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

private FunctionImpl genUnaryOperatorImpl(OperatorFunction func, Inner, Return)() {
    FunctionImpl implementation = (stack) {
        enum op = FUNCTION_TO_DLANG_OPERATOR[func].positionalReplace("stack.pop!Inner()");
        mixin("stack.push!Return(cast(Return) (" ~ op ~ "));");
    };
    return implementation;
}

private FunctionImpl genCastImpl(From, To)() {
    FunctionImpl implementation = (stack) {
        mixin("stack.push!To(cast(To) stack.pop!From());");
    };
    return implementation;
}

private FunctionImpl genBinaryOperatorImpl(OperatorFunction func, Left, Right, Return)() {
    FunctionImpl implementation = (stack) {
        enum op = FUNCTION_TO_DLANG_OPERATOR[func].positionalReplace("stack.pop!Left()", "stack.pop!Right()");
        mixin("stack.push!Return(cast(Return) (" ~ op ~ "));");
    };
    return implementation;
}

private FunctionImpl genTernaryOperatorImpl(OperatorFunction func, Left, Middle, Right, Return)() {
    FunctionImpl implementation = (stack) {
        enum op = FUNCTION_TO_DLANG_OPERATOR[func].positionalReplace("stack.pop!Left()", "stack.pop!Middle()",
                "stack.pop!Right()");
                mixin("stack.push!Return(cast(Return) (" ~ op ~ "));");
    };
    return implementation;
}
