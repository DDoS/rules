module ruleslang.semantic.context;

import ruleslang.semantic.type;
import ruleslang.semantic.function_;

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

public enum IntrinsicFunction : string {
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

public class IntrinsicNameSpace : NameSpace {
    private static immutable immutable(Function)[] unaryOperators;
    private static immutable immutable(Function)[] binaryOperators;

    public static this() {
        immutable(Function)[] functions = [];
        // Operator unary -
        foreach (type; AtomicType.NUMERIC_TYPES) {
            functions ~= new immutable Function(IntrinsicFunction.NEGATE_FUNCTION, [type], type.asSigned());
        }
        // Operator unary +
        foreach (type; AtomicType.NUMERIC_TYPES) {
            functions ~= new immutable Function(IntrinsicFunction.REAFFIRM_FUNCTION, [type], type);
        }
        // Operator unary !
        functions ~= new immutable Function(IntrinsicFunction.LOGICAL_NOT_FUNCTION, [AtomicType.BOOL], AtomicType.BOOL);
        // Operator unary ~
        foreach (type; AtomicType.INTEGER_TYPES) {
            functions ~= new immutable Function(IntrinsicFunction.BITWISE_NOT_FUNCTION, [type], type);
        }
        unaryOperators = functions.idup;
        functions.length = 0;
        // Operators binary **, *, /, %, +, -
        foreach (type; AtomicType.NUMERIC_TYPES) {
            functions ~= new immutable Function(IntrinsicFunction.EXPONENT_FUNCTION, [type, type], type);
            functions ~= new immutable Function(IntrinsicFunction.MULTIPLY_FUNCTION, [type, type], type);
            functions ~= new immutable Function(IntrinsicFunction.DIVIDE_FUNCTION, [type, type], type);
            functions ~= new immutable Function(IntrinsicFunction.REMAINDER_FUNCTION, [type, type], type);
            functions ~= new immutable Function(IntrinsicFunction.ADD_FUNCTION, [type, type], type);
            functions ~= new immutable Function(IntrinsicFunction.SUBTRACT_FUNCTION, [type, type], type);
        }
        // Operators binary <<, >>, >>>
        foreach (type; AtomicType.INTEGER_TYPES) {
            functions ~= new immutable Function(IntrinsicFunction.LEFT_SHIFT_FUNCTION, [type, AtomicType.UINT64], type);
            functions ~= new immutable Function(IntrinsicFunction.ARITHMETIC_RIGHT_SHIFT_FUNCTION, [type, AtomicType.UINT64], type);
            functions ~= new immutable Function(IntrinsicFunction.LOGICAL_RIGHT_SHIFT_FUNCTION, [type, AtomicType.UINT64], type);
        }
        // Operators binary ==, !=, <, >, <=, >=
        foreach (type; AtomicType.ALL_TYPES) {
            functions ~= new immutable Function(IntrinsicFunction.EQUALS_FUNCTION, [type, type], AtomicType.BOOL);
            functions ~= new immutable Function(IntrinsicFunction.NOT_EQUALS_FUNCTION, [type, type], AtomicType.BOOL);
            functions ~= new immutable Function(IntrinsicFunction.LESSER_THAN_FUNCTION, [type, type], AtomicType.BOOL);
            functions ~= new immutable Function(IntrinsicFunction.GREATER_THAN_FUNCTION, [type, type], AtomicType.BOOL);
            functions ~= new immutable Function(IntrinsicFunction.LESSER_OR_EQUAL_TO_FUNCTION, [type, type], AtomicType.BOOL);
            functions ~= new immutable Function(IntrinsicFunction.GREATER_OR_EQUAL_TO_FUNCTION, [type, type], AtomicType.BOOL);
        }
        // Operators binary &, ^, |
        foreach (type; AtomicType.INTEGER_TYPES) {
            functions ~= new immutable Function(IntrinsicFunction.BITWISE_AND_FUNCTION, [type, type], type);
            functions ~= new immutable Function(IntrinsicFunction.BITWISE_XOR_FUNCTION, [type, type], type);
            functions ~= new immutable Function(IntrinsicFunction.BITWISE_OR_FUNCTION, [type, type], type);
        }
        // Operators binary &&, ^^, ||
        functions ~= new immutable Function(IntrinsicFunction.LOGICAL_AND_FUNCTION, [AtomicType.BOOL, AtomicType.BOOL], AtomicType.BOOL);
        functions ~= new immutable Function(IntrinsicFunction.LOGICAL_XOR_FUNCTION, [AtomicType.BOOL, AtomicType.BOOL], AtomicType.BOOL);
        functions ~= new immutable Function(IntrinsicFunction.LOGICAL_OR_FUNCTION, [AtomicType.BOOL, AtomicType.BOOL], AtomicType.BOOL);
        // TODO: operators ~, ..
        binaryOperators = functions.idup;
    }

    public override immutable(Function)[] getFunctions(string name, immutable(Type)[] argumentTypes) {
        if (argumentTypes.length <= 0 || argumentTypes.length > 2) {
            return [];
        }
        immutable Function[] search = argumentTypes.length == 1 ? unaryOperators : binaryOperators;
        immutable(Function)[] functions = [];
        foreach (func; search) {
            if (name == func.name && func.isApplicable(argumentTypes)) {
                functions ~= func;
            }
        }
        return functions;
    }
}
