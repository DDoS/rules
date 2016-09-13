module ruleslang.semantic.context;

import std.exception : assumeUnique;
import std.meta : AliasSeq;
import std.format : format;

import ruleslang.syntax.source;
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

    public immutable(Type) resolveType(string name) {
        // Search the name spaces in order of priority without shadowing
        immutable(Type)[] types = [];
        foreach (names; priority) {
            auto type = names.getType(name);
            if (type is null) {
                continue;
            }
            types ~= type;
        }
        if (types.length > 1) {
            throw new Exception(format("Found more than one type for the name %s", name));
        }
        return types.length <= 0 ? null : types[0];
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
        // Search the name spaces in order of priority without shadowing
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
    auto reduced = applicables.removeLesser!false();
    // Only one function should remain
    if (reduced.length == 1) {
        return reduced[0].func;
    }
    // Otherwise retry, but allow narrowing this time
    reduced = applicables.removeLesser!true();
    if (reduced.length == 1) {
        return reduced[0].func;
    }
    // Otherwise the overloads cannot be resolved
    throw new Exception(format("Cannot resolve overloads, any of the following functions are applicable:\n    %s\n",
            reduced.join!("\n    ", "a.func.toString()")));
}

private immutable(ApplicableFunction)[] removeLesser(bool narrowing)(immutable(ApplicableFunction)[] applicables) {
    // Compare each function against each other
    assert (applicables.length > 0);
    auto parameterCount = applicables[0].func.parameterCount;
    for (size_t a = 0; a < applicables.length; a++) {
        auto applicableA = applicables[a];
        // If narrowing isn't allowed and the conversions require narrowing then remove it immediately
        static if (!narrowing) {
            if (applicableA.isNarrowing()) {
                applicables = applicables[0 .. a] ~ applicables[a + 1 .. $];
                a -= 1;
                continue;
            }
        }
        for (size_t b = 0; b < applicables.length; b++) {
            // Don't compare against itself
            if (a == b) {
                continue;
            }
            auto applicableB = applicables[b];
            // Remove B if A is more applicable
            if (applicableA.isMoreApplicable(applicableB)) {
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

private bool isMoreApplicable(immutable ApplicableFunction a, immutable ApplicableFunction b) {
    assert (a.func.parameterCount == b.func.parameterCount);
    // Function B must be lesser for any parameter pair
    bool lesserB = false;
    foreach (i; 0 .. b.func.parameterCount) {
        if (isLesser(b.func.parameterTypes[i], b.argumentConversions[i],
                a.func.parameterTypes[i], a.argumentConversions[i])) {
            lesserB = true;
            break;
        }
    }
    // Function A must not be lesser for any parameter pair
    bool lesserA = false;
    foreach (i; 0 .. a.func.parameterCount) {
        if (isLesser(a.func.parameterTypes[i], a.argumentConversions[i],
                b.func.parameterTypes[i], b.argumentConversions[i])) {
            lesserA = true;
            break;
        }
    }
    return lesserB && !lesserA;
}

private bool isLesser(immutable Type paramA, ConversionKind convA, immutable Type paramB, ConversionKind convB) {
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

public immutable struct ApplicableFunction {
    public Function func;
    public ConversionKind[] argumentConversions;

    public this(immutable(Function) func, immutable(ConversionKind)[] argumentConversions) {
        this.func = func;
        this.argumentConversions = argumentConversions;
    }

    public bool isNarrowing() {
        foreach (conversion; argumentConversions) {
            if (conversion is ConversionKind.NARROWING) {
                return true;
            }
        }
        return false;
    }
}

public interface NameSpace {
    public immutable(Type) getType(string name);
    public immutable(Field) getField(string name);
    public immutable(ApplicableFunction)[] getFunctions(string name, immutable(Type)[] argumentTypes);
}

public class ForeignNameSpace : NameSpace {
    public override immutable(Type) getType(string name) {
        return null;
    }

    public override immutable(Field) getField(string name) {
        return null;
    }

    public override immutable(ApplicableFunction)[] getFunctions(string name, immutable(Type)[] argumentTypes) {
        return [];
    }
}

public class ImportedNameSpace : NameSpace {
    public override immutable(Type) getType(string name) {
        return null;
    }

    public override immutable(Field) getField(string name) {
        return null;
    }

    public override immutable(ApplicableFunction)[] getFunctions(string name, immutable(Type)[] argumentTypes) {
        return [];
    }
}

public class ScopeNameSpace : NameSpace {
    private ScopeNameSpace parent;

    public override immutable(Type) getType(string name) {
        return null;
    }

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
    LOGICAL_XOR_FUNCTION = "opLogicalXor",
    CONCATENATE_FUNCTION = "opConcatenate",
    RANGE_FUNCTION = "opRange",
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
    private static enum string LENGTH_NAME = "len";
    private static enum string LENGTH_SYMBOLIC_NAME = LENGTH_NAME ~ "({})" ~ getWordType().toString();
    private static immutable FunctionImpl LENGTH_IMPLEMENTATION;
    private static enum string CONCATENATE_NAME = OperatorFunction.CONCATENATE_FUNCTION;
    private static enum string CONCATENATE_SYMBOLIC_NAME = CONCATENATE_NAME ~ "({}, {}){}";
    private static immutable FunctionImpl CONCATENATE_IMPLEMENTATION;
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
        binaryFunctions ~= genBinaryFunctions!(OperatorFunction.LOGICAL_XOR_FUNCTION, Same, Same, bool)();
        // Operator binary ..
        binaryFunctions ~= genRangeFunctions!(int, uint, long, ulong, float, double)();
        auto assocBinaryFunctions = binaryFunctions.associateArrays!getName();
        binaryOperators = assocBinaryFunctions.assumeUnique();
        // Implementation of the generated functions
        LENGTH_IMPLEMENTATION = (runtime, func) {
            auto address = runtime.stack.pop!(void*);
            if (address is null) {
                throw new SourceException("Null reference", size_t.max, size_t.max);
            }
            auto dataSegment = address + TypeIndex.sizeof;
            auto length = *(cast(size_t*) dataSegment);
            runtime.stack.push!size_t(length);
        };
        CONCATENATE_IMPLEMENTATION = (runtime, func) {
            // Get the array addresses
            auto addressA = runtime.stack.pop!(void*);
            if (addressA is null) {
                throw new SourceException("Null reference", size_t.max, size_t.max);
            }
            auto addressB = runtime.stack.pop!(void*);
            if (addressB is null) {
                throw new SourceException("Null reference", size_t.max, size_t.max);
            }
            // Get the array data segments
            auto dataSegmentA = addressA + TypeIndex.sizeof;
            auto dataSegmentB = addressB + TypeIndex.sizeof;
            // Get the array length
            auto lengthA = *(cast(size_t*) dataSegmentA);
            auto lengthB = *(cast(size_t*) dataSegmentB);
            // Allocate the new array from the common type and the summed length
            auto type = runtime.getType(*(cast(TypeIndex*) addressA)).castOrFail!(immutable ArrayType);
            auto lengthC = lengthA + lengthB;
            auto addressC = runtime.allocateArray(type, lengthC);
            // Get the new array data segment
            auto dataSegmentC = addressC + TypeIndex.sizeof;
            // Get the container part of all three arrays
            auto containerA = dataSegmentA + size_t.sizeof;
            auto containerB = dataSegmentB + size_t.sizeof;
            auto containerC = dataSegmentC + size_t.sizeof;
            // Convert the lengths to byte size
            auto componentSize = type.getDataLayout().componentSize;
            lengthA *= componentSize;
            lengthB *= componentSize;
            lengthC *= componentSize;
            // Copy the data
            containerC[0 .. lengthA] = containerA[0 .. lengthA];
            containerC[lengthA .. lengthC] = containerB[0 .. lengthB];
            // Push the new array to the stack
            runtime.stack.push!(void*)(addressC);
        };
        // Create the function implementation lookup table
        void addNoReplace(ref FunctionImpl[string] array, string symbolicName, FunctionImpl impl) {
            auto already = symbolicName in array;
            assert (already is null);
            array[symbolicName] = impl;
        }
        FunctionImpl[string] functionImpls;
        foreach (intrinsic; unaryFunctions) {
            addNoReplace(functionImpls, intrinsic.func.symbolicName, intrinsic.impl);
        }
        foreach (intrinsic; binaryFunctions) {
            addNoReplace(functionImpls, intrinsic.func.symbolicName, intrinsic.impl);
        }
        addNoReplace(functionImpls, LENGTH_SYMBOLIC_NAME, LENGTH_IMPLEMENTATION);
        addNoReplace(functionImpls, CONCATENATE_SYMBOLIC_NAME, CONCATENATE_IMPLEMENTATION);
        FUNCTION_IMPLEMENTATIONS = functionImpls.assumeUnique();
    }

    private this() {
    }

    public override immutable(Type) getType(string name) {
        auto type = name in AtomicType.BY_NAME;
        return type is null ? null : *type;
    }

    public override immutable(Field) getField(string name) const {
        return null;
    }

    public override immutable(ApplicableFunction)[] getFunctions(string name, immutable(Type)[] argumentTypes) {
        if (argumentTypes.length <= 0 || argumentTypes.length > 3) {
            return [];
        }
        // Search for functions that can be applied to the argument types
        IntrinsicFunctions searchFunctions = getPossibleFunctions(name, argumentTypes);
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
        IntrinsicFunctions searchFunctions = getPossibleFunctions(name, parameterTypes);
        foreach (intrinsic; searchFunctions) {
            auto func = intrinsic.func;
            if (func.isExactly(name, parameterTypes)) {
                return func;
            }
        }
        return null;
    }

    private static IntrinsicFunctions getPossibleFunctions(string name, immutable(Type)[] argumentTypes) {
        IntrinsicFunctions* searchFunctions;
        switch (argumentTypes.length) {
            case 1:
                searchFunctions = name in unaryOperators;
                break;
            case 2:
                searchFunctions = name in binaryOperators;
                break;
            default:
                searchFunctions = null;
        }
        IntrinsicFunctions generatedFunctions = getGeneratedFunctions(name, argumentTypes);
        if (searchFunctions == null) {
            return generatedFunctions;
        }
        return *searchFunctions ~ generatedFunctions;
    }

    private static IntrinsicFunctions getGeneratedFunctions(string name, immutable(Type)[] argumentTypes) {
        if (name == LENGTH_NAME && argumentTypes.length == 1) {
            // The argument type should be an array
            auto arrayType = cast(immutable ArrayType) argumentTypes[0];
            if (arrayType is null) {
                return [];
            }
            // Generate a function that takes that argument type and returns the length as the word type
            auto paramType = arrayType.withoutLiteral();
            auto func = new immutable Function(LENGTH_NAME, LENGTH_SYMBOLIC_NAME, [paramType], getWordType());
            return [immutable IntrinsicFunction(func, LENGTH_IMPLEMENTATION)];
        }
        if (name == CONCATENATE_NAME && argumentTypes.length == 2) {
            immutable(IntrinsicFunction)[] funcs;
            //  If the first argument is an array type, try using it as the parameter type
            auto arrayTypeA = cast(immutable ArrayType) argumentTypes[0];
            auto paramTypeA = arrayTypeA is null ? null : arrayTypeA.withoutLiteral().withoutSize();
            if (paramTypeA !is null) {
                auto funcA = new immutable Function(CONCATENATE_NAME, CONCATENATE_SYMBOLIC_NAME, [paramTypeA, paramTypeA],
                        paramTypeA);
                funcs ~= immutable IntrinsicFunction(funcA, CONCATENATE_IMPLEMENTATION);
            }
            //  If the second argument is a different array type, try also using it as the parameter type
            auto arrayTypeB = cast(immutable ArrayType) argumentTypes[1];
            auto paramTypeB = arrayTypeB is null ? null : arrayTypeB.withoutLiteral().withoutSize();
            if (paramTypeB !is null) {
                if (!paramTypeB.opEquals(paramTypeA)) {
                    auto funcB = new immutable Function(CONCATENATE_NAME, CONCATENATE_SYMBOLIC_NAME, [paramTypeB, paramTypeB],
                            paramTypeB);
                    funcs ~= immutable IntrinsicFunction(funcB, CONCATENATE_IMPLEMENTATION);
                }
            }
            return funcs;
        }
        return [];
    }
}

private immutable(AtomicType) getWordType()() {
    static if (size_t.sizeof == 4) {
        return AtomicType.UINT32;
    } else static if (size_t.sizeof == 8) {
        return AtomicType.UINT64;
    } else {
        static assert (0);
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

private immutable(IntrinsicFunction)[] genRangeFunctions(Param, Params...)() {
    auto paramType = atomicTypeFor!Param();
    auto returnType = genRangeReturnType(paramType);
    auto func = new immutable Function(OperatorFunction.RANGE_FUNCTION, [paramType, paramType], returnType);
    auto impl = genRangeOperatorImpl!Param();
    auto funcs = [immutable IntrinsicFunction(func, impl)];
    static if (Params.length > 0) {
        funcs ~= genRangeFunctions!Params();
    }
    return funcs;
}

private immutable(StructureType) genRangeReturnType(immutable AtomicType paramType) {
    return new immutable StructureType([paramType, paramType], ["from", "to"]);
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
    "opLogicalXor": "$0 ^ $1",
];

private FunctionImpl genUnaryOperatorImpl(OperatorFunction opFunc, Inner, Return)() {
    FunctionImpl implementation = (runtime, func) {
        enum op = FUNCTION_TO_DLANG_OPERATOR[opFunc].positionalReplace("runtime.stack.pop!Inner()");
        mixin("runtime.stack.push!Return(cast(Return) (" ~ op ~ "));");
    };
    return implementation;
}

private FunctionImpl genCastImpl(From, To)() {
    FunctionImpl implementation = (runtime, func) {
        mixin("runtime.stack.push!To(cast(To) runtime.stack.pop!From());");
    };
    return implementation;
}

private FunctionImpl genBinaryOperatorImpl(OperatorFunction opFunc, Left, Right, Return)() {
    FunctionImpl implementation = (runtime, func) {
        enum op = FUNCTION_TO_DLANG_OPERATOR[opFunc].positionalReplace("runtime.stack.pop!Left()", "runtime.stack.pop!Right()");
        mixin("runtime.stack.push!Return(cast(Return) (" ~ op ~ "));");
    };
    return implementation;
}

private FunctionImpl genRangeOperatorImpl(Param)() {
    FunctionImpl implementation = (runtime, func) {
        auto returnType = func.returnType.castOrFail!(immutable ReferenceType);
        auto address = runtime.allocateComposite(returnType);
        auto dataLayout = returnType.getDataLayout();
        auto dataSegment = address + TypeIndex.sizeof;
        runtime.stack.popTo!Param(dataSegment + dataLayout.memberOffsetByName["from"]);
        runtime.stack.popTo!Param(dataSegment + dataLayout.memberOffsetByName["to"]);
        runtime.stack.push!(void*)(address);
    };
    return implementation;
}
