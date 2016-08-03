module ruleslang.semantic.context;

import ruleslang.semantic.type;
import ruleslang.semantic.function_;

public class Context {
    private Context parent;
    private ForeignNameSpace foreignNames;
    private ImportedNameSpace importedNames;
    private ScopeNameSpace scopeNames;
    private IntrisicNameSpace intrisicNames;
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

public class IntrisicNameSpace : NameSpace {
    public static immutable string NEGATE_FUNCTION = "opNegate";
    public static immutable string REAFFIRM_FUNCTION = "opReaffirm";
    public static immutable string LOGICAL_NOT_FUNCTION = "opLogicalNot";
    public static immutable string BITWISE_NOT_FUNCTION = "opBitwiseNot";
    private static immutable string[] unaryOperators = [
        NEGATE_FUNCTION, REAFFIRM_FUNCTION, LOGICAL_NOT_FUNCTION, BITWISE_NOT_FUNCTION
    ];
    public static immutable string EXPONENT_FUNCTION = "opExponent";
    public static immutable string MULTIPLY_FUNCTION = "opMultiply";
    public static immutable string DIVIDE_FUNCTION = "opDivide";
    public static immutable string REMAINDER_FUNCTION = "opRemainder";
    public static immutable string ADD_FUNCTION = "opAdd";
    public static immutable string SUBTRACT_FUNCTION = "opSubtract";
    public static immutable string LEFT_SHIFT_FUNCTION = "opLeftShift";
    public static immutable string ARITHMETIC_RIGHT_SHIFT_FUNCTION = "opArithmeticRightShift";
    public static immutable string LOGICAL_RIGHT_SHIFT_FUNCTION = "opLogicalRightShift";
    public static immutable string EQUALS_FUNCTION = "opEquals";
    public static immutable string NOT_EQUALS_FUNCTION = "opNotEquals";
    public static immutable string LESSER_THAN_FUNCTION = "opLesserThan";
    public static immutable string GREATER_THAN_FUNCTION = "opGreaterThan";
    public static immutable string LESSER_OR_EQUAL_TO_FUNCTION = "opLesserOrEqualTo";
    public static immutable string GREATER_OR_EQUAL_TO_FUNCTION = "opGreaterOrEqualTo";
    public static immutable string BITWISE_AND_FUNCTION = "opBitwiseAnd";
    public static immutable string BITWISE_XOR_FUNCTION = "opBitwiseXor";
    public static immutable string BITWISE_OR_FUNCTION = "opBitwiseOr";
    public static immutable string LOGICAL_AND_FUNCTION = "opLogicalAnd";
    public static immutable string LOGICAL_XOR_FUNCTION = "opLogicalXor";
    public static immutable string LOGICAL_OR_FUNCTION = "opLogicalOr";
    public static immutable string CONCATENATE_FUNCTION = "opConcatenate";
    public static immutable string RANGE_FUNCTION = "opRange";

    public override Function[] getFunctions(string name, inout Type[] argumentTypes...) {
        return [];
    }
}
