module ruleslang.semantic.tree;

import std.conv : to;
import std.format : format;

import ruleslang.semantic.type;
import ruleslang.semantic.symbol;
import ruleslang.semantic.context;
import ruleslang.evaluation.evaluate;
import ruleslang.evaluation.runtime;
import ruleslang.util;

public immutable interface Node {
    public immutable(Node)[] getChildren();
    public void evaluate(Runtime runtime);
    public string toString();
}

public immutable interface TypedNode : Node {
    public immutable(TypedNode)[] getChildren();
    public immutable(Type) getType();
}

public immutable interface LiteralNode : TypedNode {
    public immutable(LiteralType) getType();
    public immutable(LiteralNode) specializeTo(immutable Type type);
}

public immutable class NullNode : TypedNode {
    public static immutable NullNode INSTANCE = new immutable NullNode();

    private this() {
    }

    public override immutable(TypedNode)[] getChildren() {
        return [];
    }

    public override immutable(Type) getType() {
        return AtomicType.BOOL;
    }

    public override void evaluate(Runtime runtime) {
        assert (0);
    }

    public override string toString() {
        return "Null()";
    }
}

public immutable class BooleanLiteralNode : LiteralNode {
    private BooleanLiteralType type;

    public this(bool value) {
        type = new immutable BooleanLiteralType(value);
    }

    public override immutable(TypedNode)[] getChildren() {
        return [];
    }

    public override immutable(BooleanLiteralType) getType() {
        return type;
    }

    public override immutable(LiteralNode) specializeTo(immutable Type specialType) {
        if (specialType == AtomicType.BOOL) {
            return this;
        }
        return null;
    }

    public override void evaluate(Runtime runtime) {
        Evaluator.INSTANCE.evaluateBooleanLiteral(runtime, this);
    }

    public override string toString() {
        return format("BooleanLiteral(%s)", type.value);
    }
}

public immutable class StringLiteralNode : LiteralNode {
    private StringLiteralType type;

    public this(dstring value) {
        type = new immutable StringLiteralType(value);
    }

    public override immutable(TypedNode)[] getChildren() {
        return [];
    }

    public override immutable(StringLiteralType) getType() {
        return type;
    }

    public override immutable(LiteralNode) specializeTo(immutable Type specialType) {
        return null;
    }

    public override void evaluate(Runtime runtime) {
        Evaluator.INSTANCE.evaluateStringLiteral(runtime, this);
    }

    public override string toString() {
        return format("StringLiteral(\"%s\")", type.value);
    }
}

public immutable class SignedIntegerLiteralNode : LiteralNode {
    private SignedIntegerLiteralType type;
    private AtomicType specialType;

    public this(long value) {
        auto type = new immutable SignedIntegerLiteralType(value);
        this(type, type.getBackingType());
    }

    private this(immutable SignedIntegerLiteralType type, immutable AtomicType specialType) {
        this.type = type;
        assert (specialType.isInteger());
        this.specialType = specialType;
    }

    public override immutable(TypedNode)[] getChildren() {
        return [];
    }

    public override immutable(SignedIntegerLiteralType) getType() {
        return type;
    }

    public override immutable(LiteralNode) specializeTo(immutable Type specialType) {
        if (this.specialType.opEquals(specialType)) {
            return this;
        }
        auto atomicSpecial = cast(immutable AtomicType) specialType;
        if (atomicSpecial !is null) {
            if (atomicSpecial.isInteger()) {
                return new immutable SignedIntegerLiteralNode(type, atomicSpecial);
            }
            if (atomicSpecial.isFloat()) {
                return new immutable FloatLiteralNode(type.value()).specializeTo(specialType);
            }
        }
        return null;
    }

    public override void evaluate(Runtime runtime) {
        Evaluator.INSTANCE.evaluateSignedIntegerLiteral(runtime, this);
    }

    public override string toString() {
        return format("SignedIntegerLiteral(%d)", type.value);
    }
}

public immutable class UnsignedIntegerLiteralNode : LiteralNode {
    private UnsignedIntegerLiteralType type;
    private AtomicType specialType;

    public this(ulong value) {
        auto type = new immutable UnsignedIntegerLiteralType(value);
        this(type, type.getBackingType());
    }

    private this(immutable UnsignedIntegerLiteralType type, immutable AtomicType specialType) {
        this.type = type;
        assert (specialType.isInteger());
        this.specialType = specialType;
    }

    public override immutable(TypedNode)[] getChildren() {
        return [];
    }

    public override immutable(UnsignedIntegerLiteralType) getType() {
        return type;
    }

    public override immutable(LiteralNode) specializeTo(immutable Type specialType) {
        if (this.specialType.opEquals(specialType)) {
            return this;
        }
        auto atomicSpecial = cast(immutable AtomicType) specialType;
        if (atomicSpecial !is null) {
            if (atomicSpecial.isInteger()) {
                return new immutable UnsignedIntegerLiteralNode(type, atomicSpecial);
            }
            if (atomicSpecial.isFloat()) {
                return new immutable FloatLiteralNode(type.value()).specializeTo(specialType);
            }
        }
        return null;
    }

    public override void evaluate(Runtime runtime) {
        Evaluator.INSTANCE.evaluateUnsignedIntegerLiteral(runtime, this);
    }

    public override string toString() {
        return format("UnsignedIntegerLiteral(%d)", type.value);
    }
}

public immutable class FloatLiteralNode : LiteralNode {
    private FloatLiteralType type;
    private AtomicType specialType;

    public this(double value) {
        auto type = new immutable FloatLiteralType(value);
        this(type, type.getBackingType());
    }

    private this(immutable FloatLiteralType type, immutable AtomicType specialType) {
        this.type = type;
        assert (specialType.isFloat());
        this.specialType = specialType;
    }

    public override immutable(TypedNode)[] getChildren() {
        return [];
    }

    public override immutable(FloatLiteralType) getType() {
        return type;
    }

    public override immutable(LiteralNode) specializeTo(immutable Type specialType) {
        if (this.specialType.opEquals(specialType)) {
            return this;
        }
        auto atomicSpecial = cast(immutable AtomicType) specialType;
        if (atomicSpecial !is null && atomicSpecial.isFloat()) {
            if (atomicSpecial.isFloat()) {
                return new immutable FloatLiteralNode(type, atomicSpecial);
            }
        }
        return null;
    }

    public override void evaluate(Runtime runtime) {
        Evaluator.INSTANCE.evaluateFloatLiteral(runtime, this);
    }

    public override string toString() {
        return format("FloatLiteral(%g)", type.value);
    }
}

public immutable class EmptyLiteralNode : LiteralNode {
    public static immutable EmptyLiteralNode INSTANCE = new immutable EmptyLiteralNode();

    private this() {
    }

    public override immutable(TypedNode)[] getChildren() {
        return [];
    }

    public override immutable(AnyTypeLiteral) getType() {
        return AnyTypeLiteral.INSTANCE;
    }

    public override immutable(LiteralNode) specializeTo(immutable Type specialType) {
        return null;
    }

    public override void evaluate(Runtime runtime) {
        Evaluator.INSTANCE.evaluateEmptyLiteral(runtime, this);
    }

    public override string toString() {
        return "EmptyLiteralNode({})";
    }
}

public immutable class TupleLiteralNode : LiteralNode {
    private TypedNode[] values;
    private TupleLiteralType type;

    public this(immutable(TypedNode)[] values) {
        this.values = values;
        this.type = new immutable TupleLiteralType(values.getTypes());
    }

    public override immutable(TypedNode)[] getChildren() {
        return values;
    }

    public override immutable(TupleLiteralType) getType() {
        return type;
    }

    public override immutable(LiteralNode) specializeTo(immutable Type specialType) {
        return null;
    }

    public override void evaluate(Runtime runtime) {
        Evaluator.INSTANCE.evaluateTupleLiteral(runtime, this);
    }

    public override string toString() {
        return format("TupleLiteral({%s})", values.join!", "());
    }
}

public immutable class StructLiteralNode : LiteralNode {
    private TypedNode[] values;
    private string[] labels;
    private StructureLiteralType type;

    public this(immutable(TypedNode)[] values, immutable(string)[] labels) {
        assert(values.length > 0);
        assert(values.length == labels.length);
        this.values = values;
        this.labels = labels;
        type = new immutable StructureLiteralType(values.getTypes(), labels);
    }

    public override immutable(TypedNode)[] getChildren() {
        return values;
    }

    public override immutable(StructureLiteralType) getType() {
        return type;
    }

    public override immutable(LiteralNode) specializeTo(immutable Type specialType) {
        return null;
    }

    public override void evaluate(Runtime runtime) {
        Evaluator.INSTANCE.evaluateStructLiteral(runtime, this);
    }

    public override string toString() {
        return format("StructLiteral({%s})", stringZip!": "(labels, values).join!", "());
    }
}

public immutable struct ArrayLabel {
    public static immutable ArrayLabel OTHER = immutable ArrayLabel(0, true);
    private ulong _index;
    private bool _other;

    public this(ulong index) {
        this(index, false);
    }

    private this(ulong index, bool other) {
        _index = index;
        _other = other;
    }

    @property public ulong index() {
        assert (!_other);
        return _index;
    }

    @property public bool other() {
        return _other;
    }

    public string toString() {
        return _other ? "other" : _index.to!string;
    }
}

public immutable class ArrayLiteralNode : LiteralNode {
    private TypedNode[] values;
    private ArrayLabel[] labels;
    private SizedArrayLiteralType type;

    public this(immutable(TypedNode)[] values, immutable(ArrayLabel)[] labels) {
        assert(values.length > 0);
        assert(values.length == labels.length);
        this.values = values;
        this.labels = labels;
        // The array size if the max index label plus one
        ulong maxIndex = 0;
        foreach (label; labels) {
            if (!label.other() && label.index > maxIndex) {
                maxIndex = label.index;
            }
        }
        type = new immutable SizedArrayLiteralType(values.getTypes(), maxIndex + 1);
    }

    public override immutable(TypedNode)[] getChildren() {
        return values;
    }

    public override immutable(SizedArrayLiteralType) getType() {
        return type;
    }

    public override immutable(LiteralNode) specializeTo(immutable Type specialType) {
        return null;
    }

    public override void evaluate(Runtime runtime) {
        Evaluator.INSTANCE.evaluateArrayLiteral(runtime, this);
    }

    public override string toString() {
        return format("ArrayLiteral({%s})", stringZip!": "(labels, values).join!", "());
    }
}

private immutable(Type)[] getTypes(immutable(TypedNode)[] values) {
    immutable(Type)[] valueTypes = [];
    foreach (value; values) {
        valueTypes ~= value.getType();
    }
    return valueTypes;
}

public immutable class FieldAccessNode : TypedNode {
    private Field field;

    public this(immutable Field field) {
        this.field = field;
    }

    public override immutable(TypedNode)[] getChildren() {
        return [];
    }

    public override immutable(Type) getType() {
        return field.type();
    }

    public override void evaluate(Runtime runtime) {
        Evaluator.INSTANCE.evaluateFieldAccess(runtime, this);
    }

    public override string toString() {
        return format("FieldAccess(%s)", field.name);
    }
}

public immutable class MemberAccessNode : TypedNode {
    private TypedNode value;
    private string name;
    private Type type;

    public this(immutable TypedNode value, string name) {
        this.value = value;
        this.name = name;
        type = value.getType().castOrFail!(immutable StructureType)().getMemberType(name);
        assert (type !is null);
    }

    public override immutable(TypedNode)[] getChildren() {
        return [value];
    }

    public override immutable(Type) getType() {
        return type;
    }

    public override void evaluate(Runtime runtime) {
        Evaluator.INSTANCE.evaluateMemberAccess(runtime, this);
    }

    public override string toString() {
        return format("MemberAccess(%s(%s))", value.toString(), name);
    }
}

public immutable class IndexAccessNode : TypedNode {
    private TypedNode valueNode;
    private TypedNode indexNode;
    private Type type;

    public this(immutable TypedNode valueNode, immutable TypedNode indexNode) {
        this.valueNode = valueNode;
        this.indexNode = addCastNode(indexNode, AtomicType.UINT64);
        // Get the member type at the index
        auto compositeType = cast(immutable CompositeType) valueNode.getType();
        assert (compositeType !is null);
        // First check if we can know the index, for that it must be an integer literal type
        ulong index;
        bool indexKnown = false;
        auto integerLiteralIndex = cast(immutable IntegerLiteralType) indexNode.getType();
        if (integerLiteralIndex !is null) {
            index = integerLiteralIndex.unsignedValue();
            indexKnown = true;
        }
        // If the value is an array, just use the component type
        auto arrayType = cast(immutable ArrayType) compositeType;
        if (arrayType !is null) {
            type = arrayType.componentType();
            // If it is a sized array an we know the index then we can also do bounds checking
            auto sizedArrayType = cast(immutable SizedArrayType) arrayType;
            if (indexKnown && sizedArrayType !is null && index >= sizedArrayType.size) {
                throw new Exception(format("Index %d is out of range of array %s", index, sizedArrayType.toString()));
            }
            return;
        }
        // Otherwise if we have string literal, get the character literal at the index if it is know
        auto stringLiteralType = cast(immutable StringLiteralType) compositeType;
        if (stringLiteralType !is null) {
            if (!indexKnown) {
                // The index isn't know, use the string array type
                type = stringLiteralType.getBackingType().componentType;
                return;
            }
            auto str = stringLiteralType.value;
            if (index >= str.length) {
                throw new Exception(format("Index %d is out of range of string \"%s\"", index, str));
            }
            type = new immutable UnsignedIntegerLiteralType(str[index]);
            return;
        }
        // For any other composite type, query the member type and make sure it exists
        if (!indexKnown) {
            throw new Exception(format("Index must be known at compile time for type %s", compositeType.toString()));
        }
        auto memberType = compositeType.getMemberType(index);
        if (memberType is null) {
            throw new Exception(format("Index %d is out of range of type %s", index, compositeType.toString()));
        }
        type = memberType;
    }

    public override immutable(TypedNode)[] getChildren() {
        return [valueNode, indexNode];
    }

    public override immutable(Type) getType() {
        return type;
    }

    public override void evaluate(Runtime runtime) {
        Evaluator.INSTANCE.evaluateIndexAccess(runtime, this);
    }

    public override string toString() {
        return format("IndexAccess(%s[%s]))", valueNode.toString(), indexNode.toString());
    }
}

public immutable class FunctionCallNode : TypedNode {
    private Function func;
    private TypedNode[] arguments;

    public this(immutable Function func, immutable(TypedNode)[] arguments) {
        assert (func.parameterCount == arguments.length);
        this.func = func;
        // Wrap the argument nodes in casts to make the conversions explicits
        immutable(TypedNode)[] castArguments = [];
        foreach (i, arg; arguments) {
            castArguments ~= addCastNode(arg, func.parameterTypes[i]);
        }
        this.arguments = castArguments;
    }

    public override immutable(TypedNode)[] getChildren() {
        return arguments;
    }

    public override immutable(Type) getType() {
        return func.returnType();
    }

    public override void evaluate(Runtime runtime) {
        Evaluator.INSTANCE.evaluateFunctionCall(runtime, this);
    }

    public override string toString() {
        return format("FunctionCall(%s(%s))", func.name(), arguments.join!", "());
    }
}

private immutable(TypedNode) addCastNode(immutable TypedNode fromNode, immutable Type toType) {
    // Get the conversion chain from the node type to the parameter type
    auto fromLiteralNode = cast(immutable LiteralNode) fromNode;
    auto conversions = new TypeConversionChain();
    if (fromLiteralNode !is null) {
        bool convertible = fromLiteralNode.getType().specializableTo(toType, conversions);
        assert (convertible);
    } else {
        bool convertible = fromNode.getType().convertibleTo(toType, conversions);
        assert (convertible);
    }
    // Wrap the node in casts based on the chain conversion type
    if (conversions.isIdentity() || conversions.isReferenceWidening()) {
        // Nothing to cast
        return fromNode;
    }
    if (conversions.isNumericWidening()) {
        // If the "from" node is a literal, use specialization instead of a cast
        if (fromLiteralNode !is null) {
            return specializeNode(fromLiteralNode, toType);
        }
        // Add a call to the appropriate cast function
        auto castFunc = IntrinsicNameSpace.INSTANCE.getExactFunction(toType.toString(), [fromNode.getType()]);
        assert (castFunc !is null);
        return new immutable FunctionCallNode(castFunc, [fromNode]);
    }
    if (conversions.isNumericNarrowing()) {
        // Must us specialization instead of a cast
        assert (fromLiteralNode !is null);
        return specializeNode(fromLiteralNode, toType);
    }
    // TODO: other cast types
    throw new Exception(format("Unknown conversion chain from type %s to %s: %s",
            fromNode.getType().toString(), toType.toString(), conversions.toString()));
}

private immutable(LiteralNode) specializeNode(immutable LiteralNode fromNode, immutable Type toType) {
    auto specialized = fromNode.specializeTo(toType);
    if (specialized is null) {
        throw new Exception(format("Cannot specialize node %s to type %s", fromNode.toString(), toType.toString()));
    }
    return specialized;
}
