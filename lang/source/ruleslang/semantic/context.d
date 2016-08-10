module ruleslang.semantic.context;

import std.exception : assumeUnique;
import std.meta : AliasSeq;

import ruleslang.semantic.type;
import ruleslang.semantic.function_;
import ruleslang.evaluation.value;
import ruleslang.util;

public class Context {
    private Context parent;
    private ForeignNameSpace foreignNames;
    private ImportedNameSpace importedNames;
    private ScopeNameSpace scopeNames;
    private IntrinsicNameSpace intrisicNames;
}

public interface NameSpace {
    public immutable(Function)[] getFunctions(string name, immutable(Type)[] argumentTypes);
}

public class ForeignNameSpace : NameSpace {
    public override immutable(Function)[] getFunctions(string name, immutable(Type)[] argumentTypes) {
        assert(0);
    }
}

public class ImportedNameSpace : NameSpace {
    public override immutable(Function)[] getFunctions(string name, immutable(Type)[] argumentTypes) {
        assert(0);
    }
}

public class ScopeNameSpace : NameSpace {
    public override immutable(Function)[] getFunctions(string name, immutable(Type)[] argumentTypes) {
        assert(0);
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
    RANGE_FUNCTION = "opRange"
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
    }

    public override immutable(Function)[] getFunctions(string name, immutable(Type)[] argumentTypes) {
        if (argumentTypes.length <= 0 || argumentTypes.length > 2) {
            return [];
        }
        // If the argument are atomic literals, use their best atomic equivalent
        immutable(Type)[] literalArguments = [];
        foreach (arg; argumentTypes) {
            auto literal = cast(immutable AtomicLiteralType) arg;
            if (literal !is null) {
                literalArguments ~= literal.getAtomicType();
            }
        }
        auto hasLiteralArguments = literalArguments.length == argumentTypes.length;
        immutable(Type)[] searchArgumentTypes = hasLiteralArguments ? literalArguments : argumentTypes;
        // Search an operator that can be applied to the argument types
        immutable Function[] searchFunctions = searchArgumentTypes.length == 1 ? unaryOperators : binaryOperators;
        immutable(Function)[] functions = [];
        foreach (func; searchFunctions) {
            if (name == func.name && func.isApplicable(searchArgumentTypes)) {
                functions ~= func;
            }
        }
        if (!hasLiteralArguments) {
            return functions;
        }
        // Modify function signature if arguments are literals to also be literal
        immutable(Function)[] literalFunctions = [];
        foreach (func; functions) {
            literalFunctions ~= toLiteral(func, argumentTypes);
        }
        return literalFunctions;
    }

    private immutable(Function) toLiteral(immutable Function func, immutable(Type)[] argumentTypes) {
        // Generate the parameter types by converting the argument type to the equivalent literal type
        immutable(AtomicLiteralType)[] literalParameters = [];
        foreach (i, paramType; func.parameterTypes) {
            // Only convert functions with 64 bit numeric parameter types
            if (paramType == AtomicType.FP64) {
                auto floatLiteral = cast(immutable FloatLiteralType) argumentTypes[i];
                if (floatLiteral !is null) {
                    literalParameters ~= floatLiteral;
                } else {
                    literalParameters ~= argumentTypes[i].castOrFail!(immutable IntegerLiteralType).toFloatLiteral();
                }
            } else if (paramType == AtomicType.SINT64 || paramType == AtomicType.UINT64) {
                literalParameters ~= argumentTypes[i].castOrFail!(immutable IntegerLiteralType);
            } else {
                assert (0);
            }
        }
        // Call the function on the literal values to get the value of the return type literal
        immutable(Value)[] arguments = [];
        foreach (param; literalParameters) {
            arguments ~= param.asValue();
        }
        immutable Value result = func.impl()(arguments);
        // Create the return type literal corresponding to the return type
        auto returnType = cast(immutable AtomicType) func.returnType;
        assert (returnType !is null);
        // Using a pointer here because you can't assign an immutable value even if uninitialized
        immutable(AtomicLiteralType)* literalReturn;
        if (returnType == AtomicType.FP64) {
            immutable(AtomicLiteralType) literal = new immutable FloatLiteralType(result.as!double);
            literalReturn = &literal;
        } else if (returnType == AtomicType.SINT64) {
            immutable(AtomicLiteralType) literal = new immutable IntegerLiteralType(result.as!long);
            literalReturn = &literal;
        } else if (returnType == AtomicType.UINT64) {
            immutable(AtomicLiteralType) literal = new immutable IntegerLiteralType(result.as!ulong);
            literalReturn = &literal;
        } else {
            assert (0);
        }
        return new immutable Function(func.name, literalParameters, *literalReturn, func.impl);
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
    auto impl = genUnaryOperatorImpl!(func, Inner, Return)();
    auto funcs = [new immutable Function(func, [innerType], returnType, impl)];
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
    auto impl = genBinaryOperatorImpl!(func, Left, Right, Return)();
    auto funcs = [new immutable Function(func, [leftType, rightType], returnType, impl)];
    static if (Lefts.length > 0) {
        funcs ~= genBinaryFunctions!(func, RightFromLeft, ReturnFromLeft, Lefts)();
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
    "opNegate": "-",
    "opReaffirm": "+",
    "opLogicalNot": "!",
    "opBitwiseNot": "~",
    "opExponent": "^^",
    "opMultiply": "*",
    "opDivide": "/",
    "opRemainder": "%",
    "opAdd": "+",
    "opSubtract": "-",
    "opLeftShift": "<<",
    "opArithmeticRightShift": ">>",
    "opLogicalRightShift": ">>>",
    "opEquals": "==",
    "opNotEquals": "!=",
    "opLesserThan": "<",
    "opGreaterThan": ">",
    "opLesserOrEqualTo": "<=",
    "opGreaterOrEqualTo": ">=",
    "opBitwiseAnd": "&",
    "opBitwiseXor": "^",
    "opBitwiseOr": "|",
    "opLogicalAnd": "&&",
    "opLogicalXor": "^",
    "opLogicalOr": "||",
    "opConcatenate": "~",
    "opRange": ".p_range("
];

private FunctionImpl genUnaryOperatorImpl(OperatorFunction func, Inner, Return)() {
    FunctionImpl implementation = (arguments) {
        if (arguments.length != 1) {
            // TODO: add evaluator exceptions
            throw new Exception("Expected one arguments");
        }
        return valueOf(cast(Return) mixin(FUNCTION_TO_DLANG_OPERATOR[func] ~ "arguments[0].as!Inner"));
    };
    return implementation;
}

private FunctionImpl genBinaryOperatorImpl(OperatorFunction func, Left, Right, Return)() {
    FunctionImpl implementation = (arguments) {
        if (arguments.length != 2) {
            // TODO: add evaluator exceptions
            throw new Exception("Expected two arguments");
        }
        return valueOf(cast(Return) mixin("(arguments[0].as!Left"
                ~ FUNCTION_TO_DLANG_OPERATOR[func] ~ "arguments[1].as!Right)"));
    };
    return implementation;
}
