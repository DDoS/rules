module ruleslang.semantic.context;

import std.exception : assumeUnique;

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

public immutable string[string] OPERATOR_TO_FUNCTION;

public static this() {
    string[string] operatorToFunction = [
        "-": "opNegate",
        "+": "opReaffirm",
        "!": "opLogicalNot",
        "~": "opBitwiseNot",
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
    OPERATOR_TO_FUNCTION = operatorToFunction.assumeUnique();
}

public enum string[string] FUNCTION_TO_DLANG_OPERATOR = [
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

alias FunctionImplementation = immutable(Value) function(immutable(Value)[]);

public FunctionImplementation genBinaryOperatorImplementation(OperatorFunction func)() {
    FunctionImplementation implementation = (arguments) {
        if (arguments.length != 2) {
            // TODO: add evaluator exceptions
            throw new Exception("Expected two arguments");
        }
        return arguments[0].applyBinary!(FUNCTION_TO_DLANG_OPERATOR[func])(arguments[1]);
    };
    return implementation;
}

public class IntrinsicNameSpace : NameSpace {
    private static immutable immutable(Function)[] unaryOperators;
    private static immutable immutable(Function)[] binaryOperators;

    public static this() {
        immutable(Function)[] functions = [];
        // Operator unary -
        foreach (type; AtomicType.NUMERIC_TYPES) {
            functions ~= new immutable Function(OperatorFunction.NEGATE_FUNCTION, [type], type.asSigned());
        }
        // Operator unary +
        foreach (type; AtomicType.NUMERIC_TYPES) {
            functions ~= new immutable Function(OperatorFunction.REAFFIRM_FUNCTION, [type], type);
        }
        // Operator unary !
        functions ~= new immutable Function(OperatorFunction.LOGICAL_NOT_FUNCTION, [AtomicType.BOOL], AtomicType.BOOL);
        // Operator unary ~
        foreach (type; AtomicType.INTEGER_TYPES) {
            functions ~= new immutable Function(OperatorFunction.BITWISE_NOT_FUNCTION, [type], type);
        }
        unaryOperators = functions.idup;
        functions.length = 0;
        // Operators binary **, *, /, %, +, -
        foreach (type; AtomicType.NUMERIC_TYPES) {
            functions ~= new immutable Function(OperatorFunction.EXPONENT_FUNCTION, [type, type], type);
            functions ~= new immutable Function(OperatorFunction.MULTIPLY_FUNCTION, [type, type], type);
            functions ~= new immutable Function(OperatorFunction.DIVIDE_FUNCTION, [type, type], type);
            functions ~= new immutable Function(OperatorFunction.REMAINDER_FUNCTION, [type, type], type);
            functions ~= new immutable Function(OperatorFunction.ADD_FUNCTION, [type, type], type);
            functions ~= new immutable Function(OperatorFunction.SUBTRACT_FUNCTION, [type, type], type);
        }
        // Operators binary <<, >>, >>>
        foreach (type; AtomicType.INTEGER_TYPES) {
            functions ~= new immutable Function(OperatorFunction.LEFT_SHIFT_FUNCTION, [type, AtomicType.UINT64], type);
            functions ~= new immutable Function(OperatorFunction.ARITHMETIC_RIGHT_SHIFT_FUNCTION, [type, AtomicType.UINT64], type);
            functions ~= new immutable Function(OperatorFunction.LOGICAL_RIGHT_SHIFT_FUNCTION, [type, AtomicType.UINT64], type);
        }
        // Operators binary ==, !=, <, >, <=, >=
        foreach (type; AtomicType.ALL_TYPES) {
            functions ~= new immutable Function(OperatorFunction.EQUALS_FUNCTION, [type, type], AtomicType.BOOL);
            functions ~= new immutable Function(OperatorFunction.NOT_EQUALS_FUNCTION, [type, type], AtomicType.BOOL);
            functions ~= new immutable Function(OperatorFunction.LESSER_THAN_FUNCTION, [type, type], AtomicType.BOOL);
            functions ~= new immutable Function(OperatorFunction.GREATER_THAN_FUNCTION, [type, type], AtomicType.BOOL);
            functions ~= new immutable Function(OperatorFunction.LESSER_OR_EQUAL_TO_FUNCTION, [type, type], AtomicType.BOOL);
            functions ~= new immutable Function(OperatorFunction.GREATER_OR_EQUAL_TO_FUNCTION, [type, type], AtomicType.BOOL);
        }
        // Operators binary &, ^, |
        foreach (type; AtomicType.INTEGER_TYPES) {
            functions ~= new immutable Function(OperatorFunction.BITWISE_AND_FUNCTION, [type, type], type);
            functions ~= new immutable Function(OperatorFunction.BITWISE_XOR_FUNCTION, [type, type], type);
            functions ~= new immutable Function(OperatorFunction.BITWISE_OR_FUNCTION, [type, type], type);
        }
        // Operators binary &&, ^^, ||
        functions ~= new immutable Function(OperatorFunction.LOGICAL_AND_FUNCTION, [AtomicType.BOOL, AtomicType.BOOL], AtomicType.BOOL);
        functions ~= new immutable Function(OperatorFunction.LOGICAL_XOR_FUNCTION, [AtomicType.BOOL, AtomicType.BOOL], AtomicType.BOOL);
        functions ~= new immutable Function(OperatorFunction.LOGICAL_OR_FUNCTION, [AtomicType.BOOL, AtomicType.BOOL], AtomicType.BOOL);
        // TODO: operators ~, ..
        binaryOperators = functions.idup;
    }

    public override immutable(Function)[] getFunctions(string name, immutable(Type)[] argumentTypes) {
        if (argumentTypes.length <= 0 || argumentTypes.length > 2) {
            return [];
        }
        // If the argument are atomic literals, use their best atomic equivalent
        immutable(Type)[] literalBestAtomics = [];
        foreach (arg; argumentTypes) {
            auto literal = arg.exactCastImmutable!AtomicLiteralType;
            if (literal !is null) {
                literalBestAtomics ~= literal.getBestAtomicType();
            }
        }
        auto literalArguments = literalBestAtomics.length == argumentTypes.length;
        immutable(Type)[] searchArgumentTypes = literalArguments ? literalBestAtomics : argumentTypes;
        // Search an operator that can be applied to the argument types
        immutable Function[] searchFunctions = searchArgumentTypes.length == 1 ? unaryOperators : binaryOperators;
        immutable(Function)[] functions = [];
        foreach (func; searchFunctions) {
            if (name == func.name && func.isApplicable(searchArgumentTypes)) {
                functions ~= func;
            }
        }
        // Modify function signature if arguments are literals to also be literal
        if (literalArguments) {
            // TODO: this ^
        }
        return functions;
    }
}
