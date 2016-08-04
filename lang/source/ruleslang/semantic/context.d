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
    public Function[] getFunctions(string name, inout Type[] argumentTypes...);
}

public class ForeignNameSpace : NameSpace {
    public override Function[] getFunctions(string name, inout Type[] argumentTypes...) {
        assert(0);
    }
}

public class ImportedNameSpace : NameSpace {
    public override Function[] getFunctions(string name, inout Type[] argumentTypes...) {
        assert(0);
    }
}

public class ScopeNameSpace : NameSpace {
    public override Function[] getFunctions(string name, inout Type[] argumentTypes...) {
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
    /*private static immutable string[] unaryOperators = [
        NEGATE_FUNCTION, REAFFIRM_FUNCTION, LOGICAL_NOT_FUNCTION, BITWISE_NOT_FUNCTION
    ];
    private static immutable string[] binaryOperators = [
        EXPONENT_FUNCTION, MULTIPLY_FUNCTION, DIVIDE_FUNCTION, REMAINDER_FUNCTION,
        ADD_FUNCTION, SUBTRACT_FUNCTION, LEFT_SHIFT_FUNCTION, ARITHMETIC_RIGHT_SHIFT_FUNCTION,
        LOGICAL_RIGHT_SHIFT_FUNCTION, EQUALS_FUNCTION, NOT_EQUALS_FUNCTION, LESSER_THAN_FUNCTION,
        GREATER_THAN_FUNCTION, LESSER_OR_EQUAL_TO_FUNCTION, GREATER_OR_EQUAL_TO_FUNCTION, BITWISE_AND_FUNCTION,
        BITWISE_XOR_FUNCTION, BITWISE_OR_FUNCTION, LOGICAL_AND_FUNCTION, LOGICAL_XOR_FUNCTION,
        LOGICAL_OR_FUNCTION, CONCATENATE_FUNCTION, RANGE_FUNCTION
    ];*/

    public override Function[] getFunctions(string name, inout Type[] argumentTypes...) {
        return [];
    }
}
