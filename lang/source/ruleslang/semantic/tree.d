module ruleslang.semantic.tree;

import std.conv : to;
import std.algorithm.searching : all;
import std.format : format;

import ruleslang.syntax.source;
import ruleslang.semantic.type;
import ruleslang.semantic.symbol;
import ruleslang.semantic.context;
import ruleslang.evaluation.evaluate;
import ruleslang.evaluation.runtime;
import ruleslang.util;

public immutable interface Node {
    @property public size_t start();
    @property public size_t end();
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

    @property public override size_t start() {
        return 0;
    }

    @property public override size_t end() {
        return 0;
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

public immutable class NullLiteralNode : LiteralNode {
    private size_t _start;
    private size_t _end;

    public this(size_t start, size_t end) {
        _start = start;
        _end = end;
    }

    @property public override size_t start() {
        return _start;
    }

    @property public override size_t end() {
        return _end;
    }

    public override immutable(TypedNode)[] getChildren() {
        return [];
    }

    public override immutable(NullLiteralType) getType() {
        return NullLiteralType.INSTANCE;
    }

    public override immutable(LiteralNode) specializeTo(immutable Type specialType) {
        if (NullType.INSTANCE.opEquals(specialType)) {
            return this;
        }
        return null;
    }

    public override bool isIntrinsicEvaluable() {
        return true;
    }

    public override void evaluate(Runtime runtime) {
        Evaluator.INSTANCE.evaluateNullLiteral(runtime, this);
    }

    public override string toString() {
        return "NullLiteral(null)";
    }
}

public immutable class BooleanLiteralNode : LiteralNode {
    private BooleanLiteralType type;
    private size_t _start;
    private size_t _end;

    public this(bool value, size_t start, size_t end) {
        type = new immutable BooleanLiteralType(value);
        _start = start;
        _end = end;
    }

    @property public override size_t start() {
        return _start;
    }

    @property public override size_t end() {
        return _end;
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
    private size_t _start;
    private size_t _end;

    public this(dstring value, size_t start, size_t end) {
        type = new immutable StringLiteralType(value);
        identity = type.identity();
        _start = start;
        _end = end;
    }

    @property public override size_t start() {
        return _start;
    }

    @property public override size_t end() {
        return _end;
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
    private size_t _start;
    private size_t _end;

    public this(long value, size_t start, size_t end) {
        type = new immutable SignedIntegerLiteralType(value);
        _start = start;
        _end = end;
    }

    private this(immutable AtomicType backingType, long value, size_t start, size_t end) {
        type = new immutable SignedIntegerLiteralType(backingType, value);
        _start = start;
        _end = end;
    }

    @property public override size_t start() {
        return _start;
    }

    @property public override size_t end() {
        return _end;
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
                    return new immutable SignedIntegerLiteralNode(atomicSpecial, type.value, _start, _end);
                } else {
                    return new immutable UnsignedIntegerLiteralNode(atomicSpecial, type.value, _start, _end);
                }
            }
            if (atomicSpecial.isFloat()) {
                return new immutable FloatLiteralNode(atomicSpecial, type.value, _start, _end);
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
    private size_t _start;
    private size_t _end;

    public this(ulong value, size_t start, size_t end) {
        type = new immutable UnsignedIntegerLiteralType(value);
        _start = start;
        _end = end;
    }

    private this(immutable AtomicType backingType, ulong value, size_t start, size_t end) {
        type = new immutable UnsignedIntegerLiteralType(backingType, value);
        _start = start;
        _end = end;
    }

    @property public override size_t start() {
        return _start;
    }

    @property public override size_t end() {
        return _end;
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
                    return new immutable SignedIntegerLiteralNode(atomicSpecial, type.value, _start, _end);
                } else {
                    return new immutable UnsignedIntegerLiteralNode(atomicSpecial, type.value, _start, _end);
                }
            }
            if (atomicSpecial.isFloat()) {
                return new immutable FloatLiteralNode(atomicSpecial, type.value, _start, _end);
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
    private size_t _start;
    private size_t _end;

    public this(double value, size_t start, size_t end) {
        type = new immutable FloatLiteralType(value);
        _start = start;
        _end = end;
    }

    private this(immutable AtomicType backingType, double value, size_t start, size_t end) {
        type = new immutable FloatLiteralType(backingType, value);
        _start = start;
        _end = end;
    }

    @property public override size_t start() {
        return _start;
    }

    @property public override size_t end() {
        return _end;
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
            return new immutable FloatLiteralNode(atomicSpecial, type.value, _start, _end);
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
    private size_t _start;
    private size_t _end;

    public this(size_t start, size_t end) {
        _start = start;
        _end = end;
    }

    @property public override size_t start() {
        return _start;
    }

    @property public override size_t end() {
        return _end;
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
        auto arrayType = cast(immutable ArrayType) specialType;
        if (arrayType !is null) {
            // If the other type is sized, use a label for the size minus one
            // Otherwise label it with "other" for a size of zero
            auto sizedArrayType = cast(immutable SizedArrayType) arrayType;
            immutable ArrayLabel label = sizedArrayType is null ? ArrayLabel.asOther(_start, _end)
                    : immutable ArrayLabel(sizedArrayType.size - 1, _start, _end);
            return new immutable ArrayLiteralNode([arrayType.componentType.defaultValue(_start, _end)],
                    [label], _start, _end);
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
    private size_t _start;
    private size_t _end;

    public this(immutable(TypedNode)[] values, size_t start, size_t end) {
        this.values = values.reduceLiterals();
        this.type = new immutable TupleLiteralType(this.values.getTypes());
        identity = type.identity();
        _start = start;
        _end = end;
    }

    @property public override size_t start() {
        return _start;
    }

    @property public override size_t end() {
        return _end;
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
        auto arrayType = cast(immutable ArrayType) specialType;
        if (arrayType !is null) {
            // Specialize all the values to the component type and label them by index
            immutable(TypedNode)[] specialValues = [];
            immutable(ArrayLabel)[] specialLabels = [];
            foreach (i, value; values) {
                specialValues ~= value.addCastNode(arrayType.componentType);
                specialLabels ~= immutable ArrayLabel(i, _start, _end);
            }
            // If the other array is sized and this size is shorter, correct it
            auto sizedArrayType = cast(immutable SizedArrayType) arrayType;
            if (sizedArrayType !is null && specialValues.length < sizedArrayType.size) {
                // Add a label for size minus one and a corresponding default value
                specialLabels ~= immutable ArrayLabel(sizedArrayType.size - 1, _start, _end);
                specialValues ~= sizedArrayType.componentType.defaultValue(_start, _end);
            }
            return new immutable ArrayLiteralNode(specialValues, specialLabels, _start, _end);
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

public immutable struct StructLabel {
    public string name;
    public size_t start;
    public size_t end;

    public this(string name, size_t start, size_t end) {
        this.name = name;
        this.start = start;
        this.end = end;
    }

    public string toString() {
        return name;
    }
}

public immutable class StructLiteralNode : ReferenceNode, LiteralNode {
    public TypedNode[] values;
    private StructLabel[] labels;
    private StructureLiteralType type;
    private TypeIdentity identity;
    private size_t _start;
    private size_t _end;

    public this(immutable(TypedNode)[] values, immutable(StructLabel)[] labels, size_t start, size_t end) {
        assert(values.length > 0);
        assert(values.length == labels.length);
        this.values = values.reduceLiterals();
        // Ensure the struct labels are unique
        foreach (i, labelA; labels) {
            foreach (j, labelB; labels) {
                if (i == j) {
                    continue;
                }
                if (labelA.name == labelB.name) {
                    throw new SourceException(format("Label %s is not unique", labelA), labelA);
                }
            }
        }
        this.labels = labels;
        immutable(string)[] labelNames = [];
        foreach (label; labels) {
            labelNames ~= label.name;
        }
        type = new immutable StructureLiteralType(this.values.getTypes(), labelNames);
        identity = type.identity();
        _start = start;
        _end = end;
    }

    @property public override size_t start() {
        return _start;
    }

    @property public override size_t end() {
        return _end;
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
    private ulong _index;
    public bool other;
    public size_t start;
    public size_t end;

    public this(ulong index, size_t start, size_t end) {
        this(index, false, start, end);
    }

    private this(ulong index, bool other, size_t start, size_t end) {
        _index = index;
        this.other = other;
        this.start = start;
        this.end = end;
    }

    @property public ulong index() {
        assert (!other);
        return _index;
    }

    public bool sameIndex(immutable ArrayLabel label) {
        return other ? label.other : !label.other && _index == label._index;
    }

    public string toString() {
        return other ? "other" : _index.to!string;
    }

    public static immutable(ArrayLabel) asOther(size_t start, size_t end) {
        return immutable ArrayLabel(0, true, start, end);
    }
}

public immutable class ArrayLiteralNode : LiteralNode, ReferenceNode {
    public TypedNode[] values;
    public ArrayLabel[] labels;
    private SizedArrayLiteralType type;
    private TypeIdentity identity;
    private size_t _start;
    private size_t _end;

    public this(immutable(TypedNode)[] values, immutable(ArrayLabel)[] labels, size_t start, size_t end) {
        assert(values.length > 0);
        assert(values.length == labels.length);
        // Ensure the array labels are unique
        foreach (i, labelA; labels) {
            foreach (j, labelB; labels) {
                if (i == j) {
                    continue;
                }
                if (labelA.sameIndex(labelB)) {
                    throw new SourceException(format("Label %s is not unique", labelA.toString()), labelA);
                }
            }
        }
        this.labels = labels;
        // The array size if the max index label plus one
        ulong maxIndex = 0;
        bool hasIndexLabel = false;
        foreach (label; this.labels) {
            if (!label.other) {
                hasIndexLabel = true;
                if (label.index > maxIndex) {
                    maxIndex = label.index;
                }
            }
        }
        auto size = hasIndexLabel ? maxIndex + 1 : 0;
        // Reduce the array member literals
        auto reducedValues = values.reduceLiterals();
        // Try to create the sized array type (can fail if there is no upper bound)
        string exceptionMessage;
        type = collectExceptionMessage(new immutable SizedArrayLiteralType(reducedValues.getTypes(), size),
                exceptionMessage);
        if (exceptionMessage !is null) {
            throw new SourceException(exceptionMessage, start, end);
        }
        identity = type.identity();
        // Add casts to the component types on the values
        immutable(TypedNode)[] castValues = [];
        foreach (value; reducedValues) {
            castValues ~= value.addCastNode(type.componentType);
        }
        this.values = castValues;
        _start = start;
        _end = end;
    }

    @property public override size_t start() {
        return _start;
    }

    @property public override size_t end() {
        return _end;
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
        auto arrayType = cast(immutable ArrayType) specialType;
        if (arrayType !is null) {
            // Specialize all the values to the component type
            immutable(TypedNode)[] specialValues = [];
            foreach (value; values) {
                specialValues ~= value.addCastNode(arrayType.componentType);
            }
            // If the other array is sized and this size is shorter, correct it
            immutable(ArrayLabel)[] specialLabels = labels;
            auto sizedArrayType = cast(immutable SizedArrayType) arrayType;
            if (sizedArrayType !is null && type.size < sizedArrayType.size) {
                // Add a label for size minus one and a corresponding default value
                specialLabels ~= immutable ArrayLabel(sizedArrayType.size - 1, _start, _end);
                specialValues ~= sizedArrayType.componentType.defaultValue(_start, _end);
            }
            return new immutable ArrayLiteralNode(specialValues, specialLabels, _start, _end);
        }
        return null;
    }

    public immutable(TypedNode) getValueAt(ulong index, out bool isOther) {
        // Search for a label with the index
        foreach (i, label; labels) {
            if (!label.other && label.index == index) {
                isOther = false;
                return values[i];
            }
        }
        // Otherwise, if a label is "other", return the corresponding value
        foreach (i, label; labels) {
            if (label.other) {
                isOther = true;
                return values[i];
            }
        }
        isOther = false;
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

public immutable class FieldAccessNode : TypedNode {
    private Field field;
    private size_t _start;
    private size_t _end;

    public this(immutable Field field, size_t start, size_t end) {
        this.field = field;
        _start = start;
        _end = end;
    }

    @property public override size_t start() {
        return _start;
    }

    @property public override size_t end() {
        return _end;
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
    public TypedNode value;
    public string name;
    private Type type;
    private size_t _start;
    private size_t _end;

    public this(immutable TypedNode value, string name, size_t start, size_t end) {
        this.value = value.reduceLiterals();
        this.name = name;
        type = this.value.getType().castOrFail!(immutable StructureType)().getMemberType(name);
        assert (type !is null);
        _start = start;
        _end = end;
    }

    @property public override size_t start() {
        return _start;
    }

    @property public override size_t end() {
        return _end;
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
    public TypedNode value;
    public TypedNode index;
    private Type type;
    private size_t _start;
    private size_t _end;

    public this(immutable TypedNode value, immutable TypedNode index, size_t start, size_t end) {
        this.value = value.reduceLiterals();
        this.index = index.reduceLiterals().addCastNode(AtomicType.UINT64);
        _start = start;
        _end = end;
        // Next find the acess type
        auto referenceType = cast(immutable ReferenceType) this.value.getType();
        assert (referenceType !is null);
        // First check if we can know the index, for that it must be an integer literal type
        ulong indexValue;
        bool indexKnown = false;
        auto integerLiteralIndex = cast(immutable IntegerLiteralType) this.index.getType();
        if (integerLiteralIndex !is null) {
            indexValue = integerLiteralIndex.unsignedValue();
            indexKnown = true;
        }
        // If the index is know, get the member type at the index
        if (indexKnown) {
            type = referenceType.getMemberType(indexValue);
            // If the reference type is also a composite type, this method can return null for out-of-bounds
            if (type is null) {
                throw new SourceException(
                    format("Index %d is out of range of composite %s", indexValue, referenceType.toString()),
                    index
                );
            }
            return;
        }
        // Otherwise, for an array type, just use the component type
        auto arrayType = cast(immutable ArrayType) referenceType;
        if (arrayType !is null) {
            type = arrayType.componentType;
            return;
        }
        throw new SourceException(format("Index must be known at compile time for type %s", referenceType.toString()), index);
    }

    @property public override size_t start() {
        return _start;
    }

    @property public override size_t end() {
        return _end;
    }

    public override immutable(TypedNode)[] getChildren() {
        return [value, index];
    }

    public override immutable(Type) getType() {
        return type;
    }

    public override bool isIntrinsicEvaluable() {
        return value.isIntrinsicEvaluable() && index.isIntrinsicEvaluable();
    }

    public override void evaluate(Runtime runtime) {
        Evaluator.INSTANCE.evaluateIndexAccess(runtime, this);
    }

    public override string toString() {
        return format("IndexAccess(%s[%s]))", value.toString(), index.toString());
    }
}

public immutable class FunctionCallNode : TypedNode {
    public Function func;
    public TypedNode[] arguments;
    private size_t _start;
    private size_t _end;

    public this(immutable Function func, immutable(TypedNode)[] arguments, size_t start, size_t end) {
        assert (func.parameterCount == arguments.length);
        this.func = func;
        // Perform literal reduction then wrap the argument nodes in casts to make the conversions explicit
        immutable(TypedNode)[] castArguments = [];
        foreach (i, arg; arguments) {
            castArguments ~= arg.reduceLiterals().addCastNode(func.parameterTypes[i]);
        }
        this.arguments = castArguments;
        _start = start;
        _end = end;
    }

    @property public override size_t start() {
        return _start;
    }

    @property public override size_t end() {
        return _end;
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

public immutable class ReferenceCompareNode : TypedNode {
    public TypedNode left;
    public TypedNode right;
    public bool negated;
    private size_t _start;
    private size_t _end;

    public this(immutable TypedNode left, immutable TypedNode right, bool negated, size_t start, size_t end) {
        this.left = left;
        this.right = right;
        this.negated = negated;
        _start = start;
        _end = end;
    }

    @property public override size_t start() {
        return _start;
    }

    @property public override size_t end() {
        return _end;
    }

    public override immutable(TypedNode)[] getChildren() {
        return [left, right];
    }

    public override immutable(Type) getType() {
        return AtomicType.BOOL;
    }

    public override bool isIntrinsicEvaluable() {
        return left.isIntrinsicEvaluable() && right.isIntrinsicEvaluable();
    }

    public override void evaluate(Runtime runtime) {
        Evaluator.INSTANCE.evaluateReferenceCompare(runtime, this);
    }

    public override string toString() {
        return format("ReferenceCompare(%s %s== %s)", left.toString, negated ? "!" : "=", right.toString());
    }
}

public immutable class ConditionalNode : TypedNode {
    public TypedNode condition;
    public TypedNode whenTrue;
    public TypedNode whenFalse;
    private Type type;
    private size_t _start;
    private size_t _end;

    public this(immutable TypedNode condition, immutable TypedNode whenTrue, immutable TypedNode whenFalse,
            size_t start, size_t end) {
        this.condition = condition.reduceLiterals();
        // Reduce the literals of the possible values
        auto reducedTrue = whenTrue.reduceLiterals();
        auto reducedFalse = whenFalse.reduceLiterals();
        // The type is the LUB of the two possible values
        type = reducedTrue.getType().lowestUpperBound(reducedFalse.getType());
        if (type is null) {
            throw new SourceException(
                format("No lowest upper bound for types %s and %s", reducedTrue.getType(), reducedFalse.getType()),
                start, end
            );
        }
        // Add the cast nodes to make the conversions explicit
        this.whenTrue = reducedTrue.addCastNode(type);
        this.whenFalse = reducedFalse.addCastNode(type);
        _start = start;
        _end = end;
    }

    @property public override size_t start() {
        return _start;
    }

    @property public override size_t end() {
        return _end;
    }

    public override immutable(TypedNode)[] getChildren() {
        return [condition, whenTrue, whenFalse];
    }

    public override immutable(Type) getType() {
        return type;
    }

    public override bool isIntrinsicEvaluable() {
        return condition.isIntrinsicEvaluable() && whenTrue.isIntrinsicEvaluable() && whenFalse.isIntrinsicEvaluable();
    }

    public override void evaluate(Runtime runtime) {
        Evaluator.INSTANCE.evaluateConditional(runtime, this);
    }

    public override string toString() {
        return format("Conditional(%s, %s, %s)", condition.toString(), whenTrue.toString, whenFalse.toString());
    }
}

public immutable(Type)[] getTypes(immutable(TypedNode)[] values) {
    immutable(Type)[] valueTypes = [];
    valueTypes.reserve(values.length);
    foreach (value; values) {
        valueTypes ~= value.getType();
    }
    return valueTypes;
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
        return new immutable FunctionCallNode(castFunc, [fromNode], fromNode.start, fromNode.end);
    }
    if (conversions.isNumericNarrowing() || conversions.isReferenceNarrowing()) {
        // Must use specialization instead of a cast
        assert (fromLiteralNode !is null);
        return specializeNode(fromLiteralNode, toType);
    }
    // TODO: other conversion kinds
    throw new SourceException(
        format("Unknown conversion chain from type %s to %s: %s",
            fromNode.getType().toString(), toType.toString(), conversions.toString()),
        fromNode
    );
}

private immutable(LiteralNode) specializeNode(immutable LiteralNode fromNode, immutable Type toType) {
    auto specialized = fromNode.specializeTo(toType);
    if (specialized is null) {
        throw new SourceException(
            format("Specialization of node %s to type %s is not implemented", fromNode.toString(), toType.toString()),
            fromNode
        );
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
            return new immutable BooleanLiteralNode(value.get!bool(), node.start, node.end);
        }
        if (atomicType.isFloat()) {
            return new immutable FloatLiteralNode(atomicType, value.get!double(), node.start, node.end);
        }
        if (atomicType.isInteger()) {
            if (atomicType.isSigned()) {
                return new immutable SignedIntegerLiteralNode(atomicType, value.get!long(), node.start, node.end);
            }
            return new immutable UnsignedIntegerLiteralNode(atomicType, value.get!ulong(), node.start, node.end);
        }
    }
    // TODO: other literal types
    return node;
}

public immutable(TypedNode)[] reduceLiterals(immutable(TypedNode)[] nodes) {
    immutable(TypedNode)[] reduced = [];
    foreach (node; nodes) {
        reduced ~= node.reduceLiterals();
    }
    return reduced;
}

public immutable(TypedNode) defaultValue(immutable Type type, size_t start, size_t end) {
    // For an atomic type, simply zero-initialize
    auto atomicType = cast(immutable AtomicType) type;
    if (atomicType !is null) {
        if (atomicType.isBoolean()) {
            return new immutable BooleanLiteralNode(false, start, end);
        }
        if (atomicType.isFloat()) {
            return new immutable FloatLiteralNode(atomicType, 0, start, end);
        }
        if (atomicType.isInteger()) {
            if (atomicType.isSigned()) {
                return new immutable SignedIntegerLiteralNode(atomicType, 0, start, end);
            }
            return new immutable UnsignedIntegerLiteralNode(atomicType, 0, start, end);
        }
    }

    throw new Exception(format("No default value for type %s", type.toString()));
}
