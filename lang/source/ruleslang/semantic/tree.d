module ruleslang.semantic.tree;

import std.conv : to;
import std.algorithm.searching : all;
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
    public bool isIntrinsicEvaluable();
}

public immutable interface LiteralNode : TypedNode {
    public immutable(LiteralType) getType();
    public immutable(LiteralNode) specializeTo(immutable Type type);
}

public immutable interface ReferenceNode : TypedNode {
    public immutable(TypeIdentity) getTypeIdentity();
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

    public override bool isIntrinsicEvaluable() {
        return false;
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
        if (specialType.opEquals(AtomicType.BOOL)) {
            return this;
        }
        return null;
    }

    public override bool isIntrinsicEvaluable() {
        return true;
    }

    public override void evaluate(Runtime runtime) {
        Evaluator.INSTANCE.evaluateBooleanLiteral(runtime, this);
    }

    public override string toString() {
        return format("BooleanLiteral(%s)", type.value);
    }
}

public immutable class StringLiteralNode : ReferenceNode, LiteralNode {
    private StringLiteralType type;
    private TypeIdentity identity;

    public this(dstring value) {
        type = new immutable StringLiteralType(value);
        identity = type.identity();
    }

    public override immutable(TypedNode)[] getChildren() {
        return [];
    }

    public override immutable(StringLiteralType) getType() {
        return type;
    }

    public override immutable(TypeIdentity) getTypeIdentity() {
        return identity;
    }

    public override immutable(LiteralNode) specializeTo(immutable Type specialType) {
        return null;
    }

    public override bool isIntrinsicEvaluable() {
        return true;
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

    public this(long value) {
        type = new immutable SignedIntegerLiteralType(value);
    }

    private this(immutable AtomicType backingType, long value) {
        type = new immutable SignedIntegerLiteralType(backingType, value);
    }

    public override immutable(TypedNode)[] getChildren() {
        return [];
    }

    public override immutable(SignedIntegerLiteralType) getType() {
        return type;
    }

    public override immutable(LiteralNode) specializeTo(immutable Type specialType) {
        auto atomicSpecial = cast(immutable AtomicType) specialType;
        if (atomicSpecial !is null) {
            if (atomicSpecial.isInteger()) {
                if (atomicSpecial.isSigned()) {
                    return new immutable SignedIntegerLiteralNode(atomicSpecial, type.value);
                } else {
                    return new immutable UnsignedIntegerLiteralNode(atomicSpecial, type.value);
                }
            }
            if (atomicSpecial.isFloat()) {
                return new immutable FloatLiteralNode(atomicSpecial, type.value);
            }
        }
        return null;
    }

    public override bool isIntrinsicEvaluable() {
        return true;
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

    public this(ulong value) {
        type = new immutable UnsignedIntegerLiteralType(value);
    }

    private this(immutable AtomicType backingType, ulong value) {
        type = new immutable UnsignedIntegerLiteralType(backingType, value);
    }

    public override immutable(TypedNode)[] getChildren() {
        return [];
    }

    public override immutable(UnsignedIntegerLiteralType) getType() {
        return type;
    }

    public override immutable(LiteralNode) specializeTo(immutable Type specialType) {
        auto atomicSpecial = cast(immutable AtomicType) specialType;
        if (atomicSpecial !is null) {
            if (atomicSpecial.isInteger()) {
                if (atomicSpecial.isSigned()) {
                    return new immutable SignedIntegerLiteralNode(atomicSpecial, type.value);
                } else {
                    return new immutable UnsignedIntegerLiteralNode(atomicSpecial, type.value);
                }
            }
            if (atomicSpecial.isFloat()) {
                return new immutable FloatLiteralNode(atomicSpecial, type.value);
            }
        }
        return null;
    }

    public override bool isIntrinsicEvaluable() {
        return true;
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

    public this(double value) {
        type = new immutable FloatLiteralType(value);
    }

    private this(immutable AtomicType backingType, double value) {
        type = new immutable FloatLiteralType(backingType, value);
    }

    public override immutable(TypedNode)[] getChildren() {
        return [];
    }

    public override immutable(FloatLiteralType) getType() {
        return type;
    }

    public override immutable(LiteralNode) specializeTo(immutable Type specialType) {
        auto atomicSpecial = cast(immutable AtomicType) specialType;
        if (atomicSpecial !is null && atomicSpecial.isFloat()) {
            return new immutable FloatLiteralNode(atomicSpecial, type.value);
        }
        return null;
    }

    public override bool isIntrinsicEvaluable() {
        return true;
    }

    public override void evaluate(Runtime runtime) {
        Evaluator.INSTANCE.evaluateFloatLiteral(runtime, this);
    }

    public override string toString() {
        return format("FloatLiteral(%g)", type.value);
    }
}

public immutable class EmptyLiteralNode : ReferenceNode, LiteralNode {
    public static immutable EmptyLiteralNode INSTANCE = new immutable EmptyLiteralNode();

    private this() {
    }

    public override immutable(TypedNode)[] getChildren() {
        return [];
    }

    public override immutable(AnyTypeLiteral) getType() {
        return AnyTypeLiteral.INSTANCE;
    }

    public override immutable(TypeIdentity) getTypeIdentity() {
        return AnyType.INFO;
    }

    public override immutable(LiteralNode) specializeTo(immutable Type specialType) {
        auto ignored = new TypeConversionChain();
        if (AnyType.INSTANCE.convertibleTo(specialType, ignored)) {
            return this;
        }
        return null;
    }

    public override bool isIntrinsicEvaluable() {
        return true;
    }

    public override void evaluate(Runtime runtime) {
        Evaluator.INSTANCE.evaluateEmptyLiteral(runtime, this);
    }

    public override string toString() {
        return "EmptyLiteralNode({})";
    }
}

public immutable class TupleLiteralNode : ReferenceNode, LiteralNode {
    public TypedNode[] values;
    private TupleLiteralType type;
    private TypeIdentity identity;

    public this(immutable(TypedNode)[] values) {
        this.values = values.reduceLiterals();
        this.type = new immutable TupleLiteralType(this.values.getTypes());
        identity = type.identity();
    }

    public override immutable(TypedNode)[] getChildren() {
        return values;
    }

    public override immutable(TupleLiteralType) getType() {
        return type;
    }

    public override immutable(TypeIdentity) getTypeIdentity() {
        return identity;
    }

    public override immutable(LiteralNode) specializeTo(immutable Type specialType) {
        auto ignored = new TypeConversionChain();
        if (type.convertibleTo(specialType, ignored)) {
            return this;
        }
        return null;
    }

    public override bool isIntrinsicEvaluable() {
        return values.all!(a => a.isIntrinsicEvaluable());
    }

    public override void evaluate(Runtime runtime) {
        Evaluator.INSTANCE.evaluateTupleLiteral(runtime, this);
    }

    public override string toString() {
        return format("TupleLiteral({%s})", values.join!", "());
    }
}

public immutable class StructLiteralNode : ReferenceNode, LiteralNode {
    public TypedNode[] values;
    private string[] labels;
    private StructureLiteralType type;
    private TypeIdentity identity;

    public this(immutable(TypedNode)[] values, immutable(string)[] labels) {
        assert(values.length > 0);
        assert(values.length == labels.length);
        this.values = values.reduceLiterals();
        // Ensure the struct labels are unique
        foreach (i, labelA; labels) {
            foreach (j, labelB; labels) {
                if (i == j) {
                    continue;
                }
                if (labelA == labelB) {
                    throw new Exception(format("Label %s is not unique", labels[i]));
                }
            }
        }
        this.labels = labels;
        type = new immutable StructureLiteralType(this.values.getTypes(), labels);
        identity = type.identity();
    }

    public override immutable(TypedNode)[] getChildren() {
        return values;
    }

    public override immutable(StructureLiteralType) getType() {
        return type;
    }

    public override immutable(TypeIdentity) getTypeIdentity() {
        return identity;
    }

    public override immutable(LiteralNode) specializeTo(immutable Type specialType) {
        auto ignored = new TypeConversionChain();
        if (type.convertibleTo(specialType, ignored)) {
            return this;
        }
        return null;
    }

    public override bool isIntrinsicEvaluable() {
        return values.all!(a => a.isIntrinsicEvaluable());
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
    public bool other;
    private size_t valueIndex;

    public this(ulong index) {
        this(index, false);
    }

    private this(ulong index, bool other) {
        _index = index;
        this.other = other;
    }

    @property public ulong index() {
        assert (!other);
        return _index;
    }

    public string toString() {
        return other ? "other" : _index.to!string;
    }
}

public immutable class ArrayLiteralNode : LiteralNode, ReferenceNode {
    public TypedNode[] values;
    public ArrayLabel[] labels;
    private SizedArrayLiteralType type;
    private TypeIdentity identity;

    public this(immutable(TypedNode)[] values, immutable(ArrayLabel)[] labels) {
        assert(values.length > 0);
        assert(values.length == labels.length);
        // Ensure the array labels are unique
        foreach (i, labelA; labels) {
            foreach (j, labelB; labels) {
                if (i == j) {
                    continue;
                }
                if (labelA == labelB) {
                    throw new Exception(format("Label %s is not unique", labels[i].toString()));
                }
            }
        }
        this.labels = labels;
        // The array size if the max index label plus one
        ulong maxIndex = 0;
        foreach (label; this.labels) {
            if (!label.other && label.index > maxIndex) {
                maxIndex = label.index;
            }
        }
        auto reducedValues = values.reduceLiterals();
        type = new immutable SizedArrayLiteralType(reducedValues.getTypes(), maxIndex + 1);
        identity = type.identity();
        // Add casts to the component types on the values
        immutable(TypedNode)[] castValues = [];
        foreach (value; reducedValues) {
            castValues ~= value.addCastNode(type.componentType);
        }
        this.values = castValues;
    }

    public override immutable(TypedNode)[] getChildren() {
        return values;
    }

    public override immutable(SizedArrayLiteralType) getType() {
        return type;
    }

    public override immutable(TypeIdentity) getTypeIdentity() {
        return identity;
    }

    public override immutable(LiteralNode) specializeTo(immutable Type specialType) {
        auto ignored = new TypeConversionChain();
        if (type.convertibleTo(specialType, ignored)) {
            return this;
        }
        return null;
    }

    public immutable(TypedNode) getValueAt(ulong index) {
        // Search for a label with the index
        foreach (i, label; labels) {
            if (!label.other && label.index == index) {
                return values[i];
            }
        }
        // Otherwise, if a label is "other", return the corresponding value
        foreach (i, label; labels) {
            if (label.other) {
                return values[i];
            }
        }
        return null;
    }

    public override bool isIntrinsicEvaluable() {
        return values.all!(a => a.isIntrinsicEvaluable());
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
        return field.type;
    }

    public override bool isIntrinsicEvaluable() {
        return false;
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
        this.value = value.reduceLiterals();
        this.name = name;
        type = this.value.getType().castOrFail!(immutable StructureType)().getMemberType(name);
        assert (type !is null);
    }

    public override immutable(TypedNode)[] getChildren() {
        return [value];
    }

    public override immutable(Type) getType() {
        return type;
    }

    public override bool isIntrinsicEvaluable() {
        return value.isIntrinsicEvaluable();
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
        this.valueNode = valueNode.reduceLiterals();
        this.indexNode = addCastNode(indexNode.reduceLiterals(), AtomicType.UINT64);
        // Next find the acess type
        auto referenceType = cast(immutable ReferenceType) this.valueNode.getType();
        assert (referenceType !is null);
        // First check if we can know the index, for that it must be an integer literal type
        ulong index;
        bool indexKnown = false;
        auto integerLiteralIndex = cast(immutable IntegerLiteralType) this.indexNode.getType();
        if (integerLiteralIndex !is null) {
            index = integerLiteralIndex.unsignedValue();
            indexKnown = true;
        }
        // If the index is know, get the member type at the index
        if (indexKnown) {
            type = referenceType.getMemberType(index);
            // If the reference type is also a composite type, this method can return null for out-of-bounds
            if (type is null) {
                throw new Exception(format("Index %d is out of range of composite %s", index, referenceType.toString()));
            }
            return;
        }
        // Otherwise, for an array type, just use the component type
        auto arrayType = cast(immutable ArrayType) referenceType;
        if (arrayType !is null) {
            type = arrayType.componentType;
            return;
        }
        throw new Exception(format("Index must be known at compile time for type %s", referenceType.toString()));
    }

    public override immutable(TypedNode)[] getChildren() {
        return [valueNode, indexNode];
    }

    public override immutable(Type) getType() {
        return type;
    }

    public override bool isIntrinsicEvaluable() {
        return valueNode.isIntrinsicEvaluable() && indexNode.isIntrinsicEvaluable();
    }

    public override void evaluate(Runtime runtime) {
        Evaluator.INSTANCE.evaluateIndexAccess(runtime, this);
    }

    public override string toString() {
        return format("IndexAccess(%s[%s]))", valueNode.toString(), indexNode.toString());
    }
}

public immutable class FunctionCallNode : TypedNode {
    public Function func;
    public TypedNode[] arguments;

    public this(immutable Function func, immutable(TypedNode)[] arguments) {
        assert (func.parameterCount == arguments.length);
        this.func = func;
        // Perform literal reduction then wrap the argument nodes in casts to make the conversions explicit
        immutable(TypedNode)[] castArguments = [];
        foreach (i, arg; arguments) {
            castArguments ~= addCastNode(arg.reduceLiterals(), func.parameterTypes[i]);
        }
        this.arguments = castArguments;
    }

    public override immutable(TypedNode)[] getChildren() {
        return arguments;
    }

    public override immutable(Type) getType() {
        return func.returnType;
    }

    public override bool isIntrinsicEvaluable() {
        return arguments.all!(a => a.isIntrinsicEvaluable());
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
        auto castFunc = IntrinsicNameSpace.getExactFunction(toType.toString(), [fromNode.getType()]);
        assert (castFunc !is null);
        return new immutable FunctionCallNode(castFunc, [fromNode]);
    }
    if (conversions.isNumericNarrowing() || conversions.isReferenceNarrowing()) {
        // Must use specialization instead of a cast
        assert (fromLiteralNode !is null);
        return specializeNode(fromLiteralNode, toType);
    }
    // TODO: other conversion kinds
    throw new Exception(format("Unknown conversion chain from type %s to %s: %s",
            fromNode.getType().toString(), toType.toString(), conversions.toString()));
}

private immutable(LiteralNode) specializeNode(immutable LiteralNode fromNode, immutable Type toType) {
    auto specialized = fromNode.specializeTo(toType);
    if (specialized is null) {
        throw new Exception(format("Specialization of node %s to type %s is not implemented",
                fromNode.toString(), toType.toString()));
    }
    return specialized;
}

public immutable(TypedNode) reduceLiterals(immutable TypedNode node) {
    // First check if it can be evaluated using the intrinsic runtime
    if (!node.isIntrinsicEvaluable()) {
        return node;
    }
    // Don't attempt to further reduce an existing literal
    if (cast(immutable LiteralNode) node !is null) {
        return node;
    }
    // If it can, then do so
    auto runtime = new IntrinsicRuntime();
    try {
        node.evaluate(runtime);
    } catch (NotImplementedException) {
        return node;
    }
    // The result should be on the top of the stack
    assert (!runtime.stack.isEmpty());
    // Now we create a new literal node based on the node type
    auto atomicType = cast(immutable AtomicType) node.getType();
    if (atomicType !is null) {
        auto value = runtime.stack.pop(atomicType);
        if (atomicType.isBoolean()) {
            return new immutable BooleanLiteralNode(value.get!bool());
        }
        if (atomicType.isFloat()) {
            return new immutable FloatLiteralNode(atomicType, value.get!double());
        }
        if (atomicType.isInteger()) {
            if (atomicType.isSigned()) {
                return new immutable SignedIntegerLiteralNode(atomicType, value.get!long());
            }
            return new immutable UnsignedIntegerLiteralNode(atomicType, value.get!ulong());
        }
    }
    assert (0);
}

public immutable(TypedNode)[] reduceLiterals(immutable(TypedNode)[] nodes) {
    immutable(TypedNode)[] reduced = [];
    foreach (node; nodes) {
        reduced ~= node.reduceLiterals();
    }
    return reduced;
}

public immutable(TypedNode) defaultValue(immutable Type type) {
    // For an atomic type, simply zero-initialize
    auto atomicType = cast(immutable AtomicType) type;
    if (atomicType !is null) {
        if (atomicType.isBoolean()) {
            return new immutable BooleanLiteralNode(false);
        }
        if (atomicType.isFloat()) {
            return new immutable FloatLiteralNode(atomicType, 0);
        }
        if (atomicType.isInteger()) {
            if (atomicType.isSigned()) {
                return new immutable SignedIntegerLiteralNode(atomicType, 0);
            }
            return new immutable UnsignedIntegerLiteralNode(atomicType, 0);
        }
    }
    // For a tuple type, apply recursively on each members
    auto tupleType = cast(immutable TupleType) type;
    if (tupleType !is null) {
        immutable(TypedNode)[] values = [];
        foreach (memberType; tupleType.memberTypes) {
            values ~= defaultValue(memberType);
        }
        // For a structure type, use the same labels are the type
        auto structType = cast(immutable StructureType) tupleType;
        if (structType !is null) {
            return new immutable StructLiteralNode(values, structType.memberNames);
        }
        return new immutable TupleLiteralNode(values);
    }

    throw new Exception(format("No default value for type %s"), type.toString());
}
