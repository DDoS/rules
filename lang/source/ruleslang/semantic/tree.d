module ruleslang.semantic.tree;

import std.conv : to;
import std.algorithm.searching : any, all;
import std.format : format;
import std.typecons : Rebindable;

import ruleslang.syntax.dchars;
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
    public string toString();
}

public immutable interface FlowNode : Node {
    public bool isDeclaration();
    public Flow evaluate(Runtime runtime);
}

public struct Flow {
    public enum Action {
        PROCEED, BREAK, RERUN
    }

    public static immutable Flow PROCEED = Flow(0, false);
    private size_t targetOffset;
    private bool restart;
    public Action action;

    public this(size_t targetOffset, bool restart) inout {
        this.targetOffset = targetOffset;
        this.restart = restart;
        if (targetOffset > 0) {
            action = Action.BREAK;
        } else {
            action = restart ? Action.RERUN : Action.PROCEED;
        }
    }

    public immutable(Flow) next() inout {
        assert (targetOffset > 0);
        return immutable Flow(targetOffset - 1, restart);
    }
}

public immutable interface TypedNode : Node {
    public immutable(TypedNode)[] getChildren();
    public immutable(Type) getType();
    public bool isIntrinsicEvaluable();
    public void evaluate(Runtime runtime);
}

public immutable interface AssignableNode : TypedNode {
    public void* evaluateAddress(Runtime runtime);
}

public immutable interface LiteralNode : TypedNode {
    public immutable(LiteralType) getType();
    public immutable(LiteralNode) specializeTo(immutable Type type);
}

public immutable class NullLiteralNode : LiteralNode {
    public this(size_t start, size_t end) {
        _start = start;
        _end = end;
    }

    mixin sourceIndexFields!false;

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

    public this(bool value, size_t start, size_t end) {
        type = new immutable BooleanLiteralType(value);
        _start = start;
        _end = end;
    }

    mixin sourceIndexFields!false;

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

public immutable class StringLiteralNode : TypedNode, LiteralNode {
    private StringLiteralType type;

    public this(string value, size_t start, size_t end) {
        this(new immutable StringLiteralType(value), start, end);
    }

    public this(wstring value, size_t start, size_t end) {
        this(new immutable StringLiteralType(value), start, end);
    }

    public this(dstring value, size_t start, size_t end) {
        this(new immutable StringLiteralType(value), start, end);
    }

    public this(immutable StringLiteralType type, size_t start, size_t end) {
        this.type = type;
        _start = start;
        _end = end;
    }

    mixin sourceIndexFields!false;

    public override immutable(TypedNode)[] getChildren() {
        return [];
    }

    public override immutable(StringLiteralType) getType() {
        return type;
    }

    public override immutable(LiteralNode) specializeTo(immutable Type specialType) {
        if (type.convertibleTo(specialType)) {
            return this;
        }
        auto arrayType = cast(immutable ArrayType) specialType;
        if (arrayType !is null) {
            Rebindable!(immutable StringLiteralType) newType;
            if (arrayType.componentType.opEquals(AtomicType.UINT32)) {
                newType = type.convert!(StringLiteralType.Encoding.UTF32);
            } else if (arrayType.componentType.opEquals(AtomicType.UINT16)) {
                newType = type.convert!(StringLiteralType.Encoding.UTF16);
            } else if (arrayType.componentType.opEquals(AtomicType.UINT8)) {
                newType = type.convert!(StringLiteralType.Encoding.UTF8);
            } else {
                return null;
            }
            return new immutable StringLiteralNode(newType, _start, _end);
        }
        return null;
    }

    public override bool isIntrinsicEvaluable() {
        return true;
    }

    public override void evaluate(Runtime runtime) {
        Evaluator.INSTANCE.evaluateStringLiteral(runtime, this);
    }

    public override string toString() {
        return format("StringLiteral(\"%s\")", type.valueAs!(StringLiteralType.Encoding.UTF32).escapeString());
    }
}

public immutable class SignedIntegerLiteralNode : LiteralNode {
    private SignedIntegerLiteralType type;

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

    mixin sourceIndexFields!false;

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
                }
                return new immutable UnsignedIntegerLiteralNode(atomicSpecial, type.value, _start, _end);
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

    mixin sourceIndexFields!false;

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
                }
                return new immutable UnsignedIntegerLiteralNode(atomicSpecial, type.value, _start, _end);
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

    mixin sourceIndexFields!false;

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

public immutable class EmptyLiteralNode : TypedNode, LiteralNode {
    public this(size_t start, size_t end) {
        _start = start;
        _end = end;
    }

    mixin sourceIndexFields!false;

    public override immutable(TypedNode)[] getChildren() {
        return [];
    }

    public override immutable(AnyTypeLiteral) getType() {
        return AnyTypeLiteral.INSTANCE;
    }

    public override immutable(LiteralNode) specializeTo(immutable Type specialType) {
        if (AnyType.INSTANCE.convertibleTo(specialType)) {
            return this;
        }
        auto arrayType = cast(immutable ArrayType) specialType;
        if (arrayType !is null) {
            immutable(TypedNode)[] specialValues = [];
            immutable(ArrayLabel)[] labels = [];
            // If the other type is sized then add a value at the size minus one
            auto defaultComponent = arrayType.componentType.defaultValue(_start, _end);
            auto sizedArrayType = cast(immutable SizedArrayType) arrayType;
            if (sizedArrayType !is null && sizedArrayType.size > 0) {
                specialValues ~= defaultComponent;
                labels ~= immutable ArrayLabel(sizedArrayType.size - 1, _start, _end);
            }
            // Add a value for "other"
            specialValues ~= defaultComponent;
            labels ~= ArrayLabel.asOther(_start, _end);
            return new immutable ArrayLiteralNode(specialValues, labels, _start, _end);
        }
        auto tupleType = cast(immutable TupleType) specialType;
        if (tupleType !is null) {
            // Use default values for all members
            immutable(TypedNode)[] specialValues = [];
            foreach (memberType; tupleType.memberTypes) {
                specialValues ~= memberType.defaultValue(_start, _end);
            }
            // If the tuple type is also a structure type then add the labels
            auto structType = cast(immutable StructureType) tupleType;
            if (structType !is null) {
                immutable(StructLabel)[] labels;
                foreach (i, memberName; structType.memberNames) {
                    labels ~= immutable StructLabel(memberName, _start, _end);
                }
                return new immutable StructLiteralNode(specialValues, labels, _start, _end);
            }
            return new immutable TupleLiteralNode(specialValues, _start, _end);
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

public immutable class TupleLiteralNode : TypedNode, LiteralNode {
    public TypedNode[] values;
    private TupleLiteralType type;

    public this(immutable(TypedNode)[] values, size_t start, size_t end) {
        this.values = values;
        this.type = new immutable TupleLiteralType(this.values.getTypes());
        _start = start;
        _end = end;
    }

    mixin sourceIndexFields!false;

    public override immutable(TypedNode)[] getChildren() {
        return values;
    }

    public override immutable(TupleLiteralType) getType() {
        return type;
    }

    public override immutable(LiteralNode) specializeTo(immutable Type specialType) {
        if (type.convertibleTo(specialType)) {
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
            // For sized arrays we must make sure every component is initialized
            auto sizedArrayType = cast(immutable SizedArrayType) arrayType;
            if (sizedArrayType !is null) {
                auto defaultComponent = sizedArrayType.componentType.defaultValue(_start, _end);
                // If the array is shorther then add a value at the size minus one
                if (specialValues.length < sizedArrayType.size) {
                    specialValues ~= defaultComponent;
                    specialLabels ~= immutable ArrayLabel(sizedArrayType.size - 1, _start, _end);
                }
                // Add an "other" value
                specialValues ~= defaultComponent;
                specialLabels ~= ArrayLabel.asOther(_start, _end);
            }
            return new immutable ArrayLiteralNode(specialValues, specialLabels, _start, _end);
        }
        auto tupleType = cast(immutable TupleType) specialType;
        if (tupleType !is null) {
            // Specialize all members
            immutable(TypedNode)[] specialValues = [];
            foreach (i, value; values) {
                auto tupleMemberType = tupleType.getMemberType(i);
                specialValues ~= value.addCastNode(tupleType.getMemberType(i));
            }
            // Use default values for missing members
            foreach (i; values.length .. tupleType.getMemberCount()) {
                specialValues ~= tupleType.getMemberType(i).defaultValue(_start, _end);
            }
            // If the tuple type is also a structure type then add the labels
            auto structType = cast(immutable StructureType) tupleType;
            if (structType !is null) {
                immutable(StructLabel)[] labels;
                foreach (i, memberName; structType.memberNames) {
                    auto value = specialValues[i];
                    labels ~= immutable StructLabel(memberName, value.start, value.end);
                }
                return new immutable StructLiteralNode(specialValues, labels, _start, _end);
            }
            return new immutable TupleLiteralNode(specialValues, _start, _end);
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

public immutable class StructLiteralNode : TypedNode, LiteralNode {
    public TypedNode[] values;
    private StructLabel[] labels;
    private StructureLiteralType type;

    public this(immutable(TypedNode)[] values, immutable(StructLabel)[] labels, size_t start, size_t end) {
        assert(values.length > 0);
        assert(values.length == labels.length);
        this.values = values;
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
        _start = start;
        _end = end;
    }

    mixin sourceIndexFields!false;

    public override immutable(TypedNode)[] getChildren() {
        return values;
    }

    public override immutable(StructureLiteralType) getType() {
        return type;
    }

    public override immutable(LiteralNode) specializeTo(immutable Type specialType) {
        if (type.convertibleTo(specialType)) {
            return this;
        }
        auto structType = cast(immutable StructureType) specialType;
        if (structType !is null) {
            immutable(TypedNode)[] specialValues;
            immutable(StructLabel)[] specialLabels;
            foreach (i, memberName; structType.memberNames) {
                auto memberType = structType.memberTypes[i];
                auto index = indexOf(memberName);
                if (index < size_t.max) {
                    specialValues ~= values[index].addCastNode(memberType);
                    specialLabels ~= labels[index];
                } else {
                    specialValues ~= memberType.defaultValue(_start, _end);
                    specialLabels ~= immutable StructLabel(memberName, _start, _end);
                }
            }
            return new immutable StructLiteralNode(specialValues, specialLabels, _start, _end);
        }
        return null;
    }

    public immutable(TypedNode) getValueAt(string name) {
        auto index = indexOf(name);
        return index < size_t.max ? values[index] : null;
    }

    private size_t indexOf(string name) {
        foreach (i, label; labels) {
            if (label.name == name) {
                return i;
            }
        }
        return size_t.max;
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

public immutable class ArrayLiteralNode : TypedNode, LiteralNode {
    public TypedNode[] values;
    public ArrayLabel[] labels;
    private SizedArrayLiteralType type;

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
        // Try to create the sized array type (can fail if there is no upper bound)
        string exceptionMessage;
        type = collectExceptionMessage(new immutable SizedArrayLiteralType(values.getTypes(), size),
                exceptionMessage);
        if (exceptionMessage !is null) {
            throw new SourceException(exceptionMessage, start, end);
        }
        // Add casts to the component types on the values
        immutable(TypedNode)[] castValues = [];
        foreach (value; values) {
            castValues ~= value.addCastNode(type.componentType);
        }
        this.values = castValues;
        _start = start;
        _end = end;
    }

    mixin sourceIndexFields!false;

    public override immutable(TypedNode)[] getChildren() {
        return values;
    }

    public override immutable(SizedArrayLiteralType) getType() {
        return type;
    }

    public override immutable(LiteralNode) specializeTo(immutable Type specialType) {
        if (type.convertibleTo(specialType)) {
            return this;
        }
        auto arrayType = cast(immutable ArrayType) specialType;
        if (arrayType !is null) {
            // Specialize all the values to the component type
            immutable(TypedNode)[] specialValues = [];
            foreach (value; values) {
                specialValues ~= value.addCastNode(arrayType.componentType);
            }
            // For sized arrays we must make sure every component is initialized
            immutable(ArrayLabel)[] specialLabels = labels;
            auto sizedArrayType = cast(immutable SizedArrayType) arrayType;
            if (sizedArrayType !is null) {
                auto defaultComponent = sizedArrayType.componentType.defaultValue(_start, _end);
                // If the array is shorther then add a value at the size minus one
                if (type.size < sizedArrayType.size) {
                    specialValues ~= defaultComponent;
                    specialLabels ~= immutable ArrayLabel(sizedArrayType.size - 1, _start, _end);
                }
                // If we don't have an "other" label then add one
                bool hasOtherLabel = false;
                foreach (label; labels) {
                    if (label.other) {
                        hasOtherLabel = true;
                        break;
                    }
                }
                if (!hasOtherLabel) {
                    specialValues ~= defaultComponent;
                    specialLabels ~= ArrayLabel.asOther(_start, _end);
                }
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

public immutable class ArrayInitializer : TypedNode {
    public ArrayType type;
    public TypedNode size;
    public ArrayLiteralNode literal;

    public this(immutable TypedNode size, immutable ArrayLiteralNode literal, size_t start, size_t end) {
        if (literal.labels.length != 1 || !literal.labels[0].other) {
            throw new SourceException("Runtime arrays must have an empty literal", literal);
        }
        this.type = literal.getType().withoutSize();
        this.size = size.addCastNode(AtomicType.UINT64);
        this.literal = literal;
        _start = start;
        _end = end;
    }

    mixin sourceIndexFields!false;

    public override immutable(TypedNode)[] getChildren() {
        return [size, literal];
    }

    public override immutable(ArrayType) getType() {
        return type;
    }

    public override bool isIntrinsicEvaluable() {
        return size.isIntrinsicEvaluable() && literal.isIntrinsicEvaluable();
    }

    public override void evaluate(Runtime runtime) {
        Evaluator.INSTANCE.evaluateArrayInitializer(runtime, this);
    }

    public override string toString() {
        return format("ArrayInitializer(%s[%s]{%s})", type.componentType.toString(), size.toString(),
                stringZip!": "(literal.labels, literal.values).join!", "());
    }
}

public immutable class FieldAccessNode : AssignableNode {
    public Field field;

    public this(immutable Field field, size_t start, size_t end) {
        this.field = field;
        _start = start;
        _end = end;
    }

    mixin sourceIndexFields!false;

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

    public override void* evaluateAddress(Runtime runtime) {
        return Evaluator.INSTANCE.evaluateFieldAccessAddress(runtime, this);
    }

    public override string toString() {
        return format("FieldAccess(%s)", field.name);
    }
}

public immutable class MemberAccessNode : AssignableNode {
    public TypedNode value;
    public string name;
    private Type type;

    public this(immutable TypedNode value, string name, size_t start, size_t end) {
        this.value = value;
        this.name = name;
        type = this.value.getType().castOrFail!(immutable StructureType).getMemberType(name);
        assert (type !is null);
        _start = start;
        _end = end;
    }

    mixin sourceIndexFields!false;

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

    public override void* evaluateAddress(Runtime runtime) {
        return Evaluator.INSTANCE.evaluateMemberAccessAddress(runtime, this);
    }

    public override string toString() {
        return format("MemberAccess(%s.%s)", value.toString(), name);
    }
}

public immutable class IndexAccessNode : AssignableNode {
    public TypedNode value;
    public TypedNode index;
    private Type type;

    public this(immutable TypedNode value, immutable TypedNode index, size_t start, size_t end) {
        this.value = value;
        this.index = index.addCastNode(AtomicType.UINT64);
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

    mixin sourceIndexFields!false;

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

    public override void* evaluateAddress(Runtime runtime) {
        return Evaluator.INSTANCE.evaluateIndexAccessAddress(runtime, this);
    }

    public override string toString() {
        return format("IndexAccess(%s[%s])", value.toString(), index.toString());
    }
}

public immutable class FunctionCallNode : TypedNode {
    public Function func;
    public TypedNode[] arguments;

    public this(immutable Function func, immutable(TypedNode)[] arguments, size_t start, size_t end) {
        assert (func.parameterCount == arguments.length);
        this.func = func;
        // Perform literal reduction then wrap the argument nodes in casts to make the conversions explicit
        immutable(TypedNode)[] castArguments = [];
        foreach (i, arg; arguments) {
            castArguments ~= arg.addCastNode(func.parameterTypes[i]);
        }
        this.arguments = castArguments;
        _start = start;
        _end = end;
    }

    mixin sourceIndexFields!false;

    public override immutable(TypedNode)[] getChildren() {
        return arguments;
    }

    public override immutable(Type) getType() {
        return func.returnType;
    }

    public override bool isIntrinsicEvaluable() {
        return func.prefix == IntrinsicNameSpace.PREFIX && arguments.all!(a => a.isIntrinsicEvaluable());
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

    public this(immutable TypedNode left, immutable TypedNode right, bool negated, size_t start, size_t end) {
        this.left = left;
        this.right = right;
        this.negated = negated;
        _start = start;
        _end = end;
    }

    mixin sourceIndexFields!false;

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
        return format("ReferenceCompare(%s %s== %s)", left.toString(), negated ? "!" : "=", right.toString());
    }
}

public immutable class TypeCompareNode : TypedNode {
    public enum Kind {
        EQUAL, NOT_EQUAL, SUBTYPE, SUPERTYPE, PROPER_SUBTYPE, PROPER_SUPERTYPE, DISTINCT
    }

    public TypedNode value;
    public ReferenceType compareType;
    public TypeCompareNode.Kind kind;

    public this(immutable TypedNode value, immutable ReferenceType compareType, TypeCompareNode.Kind kind,
            size_t start, size_t end) {
        this.value = value;
        this.compareType = compareType;
        this.kind = kind;
        _start = start;
        _end = end;
    }

    mixin sourceIndexFields!false;

    public override immutable(TypedNode)[] getChildren() {
        return [value];
    }

    public override immutable(Type) getType() {
        return AtomicType.BOOL;
    }

    public override bool isIntrinsicEvaluable() {
        return value.isIntrinsicEvaluable();
    }

    public override void evaluate(Runtime runtime) {
        Evaluator.INSTANCE.evaluateTypeCompare(runtime, this);
    }

    public override string toString() {
        string operator;
        final switch (kind) with (TypeCompareNode.Kind) {
            case EQUAL:
                operator = "::";
                break;
            case NOT_EQUAL:
                operator = "!:";
                break;
            case SUBTYPE:
                operator = "<:";
                break;
            case SUPERTYPE:
                operator = ">:";
                break;
            case PROPER_SUBTYPE:
                operator = "<<:";
                break;
            case PROPER_SUPERTYPE:
                operator = ">>:";
                break;
            case DISTINCT:
                operator = "<:>";
                break;
        }
        return format("TypeCompare(%s %s %s)", value.toString(), operator, compareType.toString());
    }
}

public immutable class ConditionalNode : TypedNode {
    public TypedNode condition;
    public TypedNode whenTrue;
    public TypedNode whenFalse;
    private Type type;

    public this(immutable TypedNode condition, immutable TypedNode whenTrue, immutable TypedNode whenFalse,
            size_t start, size_t end) {
        this.condition = condition.addCastNode(AtomicType.BOOL);
        // The type is the LUB of the two possible values
        type = whenTrue.getType().lowestUpperBound(whenFalse.getType());
        if (type is null) {
            throw new SourceException(
                format("No common supertype for %s and %s", whenTrue.getType(), whenFalse.getType()),
                start, end
            );
        }
        // Add the cast nodes to make the conversions explicit
        this.whenTrue = whenTrue.addCastNode(type);
        this.whenFalse = whenFalse.addCastNode(type);
        _start = start;
        _end = end;
    }

    mixin sourceIndexFields!false;

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

public immutable class TypeDefinitionNode : FlowNode {
    public string name;
    public Type type;

    public this(string name, immutable Type type, size_t start, size_t end) {
        this.name = name;
        this.type = type;
        _start = start;
        _end = end;
    }

    mixin sourceIndexFields!false;

    public override immutable(TypedNode)[] getChildren() {
        return [];
    }

    public override bool isDeclaration() {
        return true;
    }

    public override Flow evaluate(Runtime runtime) {
        return Evaluator.INSTANCE.evaluateTypeDefinition(runtime, this);
    }

    public override string toString() {
        return format("TypeDefinition(def %s: %s)", name, type.toString());
    }
}

public immutable class FunctionCallStatementNode : FlowNode {
    public FunctionCallNode functionCall;

    public this(immutable FunctionCallNode functionCall) {
        this.functionCall = functionCall;
        _start = functionCall.start;
        _end = functionCall.end;
    }

    mixin sourceIndexFields!false;

    public override immutable(TypedNode)[] getChildren() {
        return [functionCall];
    }

    public override bool isDeclaration() {
        return false;
    }

    public override Flow evaluate(Runtime runtime) {
        return Evaluator.INSTANCE.evaluateFunctionCallStatement(runtime, this);
    }

    public override string toString() {
        return functionCall.toString();
    }
}

public immutable class VariableDeclarationNode : FlowNode {
    public Field field;
    public TypedNode value;

    public this(immutable Field field, immutable TypedNode value, size_t start, size_t end) {
        this.field = field;
        this.value = value is null ? field.type.defaultValue(end, end) : value.addCastNode(field.type);
        _start = start;
        _end = end;
    }

    mixin sourceIndexFields!false;

    public override immutable(TypedNode)[] getChildren() {
        return [value];
    }

    public override bool isDeclaration() {
        return true;
    }

    public override Flow evaluate(Runtime runtime) {
        return Evaluator.INSTANCE.evaluateVariableDeclaration(runtime, this);
    }

    public override string toString() {
        return format("VariableDeclaration(%s = %s)", field.toString(), value.toString());
    }
}

public immutable class AssignmentNode : FlowNode {
    public AssignableNode target;
    public TypedNode value;

    public this(immutable AssignableNode target, immutable TypedNode value, size_t start, size_t end) {
        this.target = target;
        this.value = value.addCastNode(target.getType());
        _start = start;
        _end = end;
    }

    mixin sourceIndexFields!false;

    public override immutable(TypedNode)[] getChildren() {
        return [target, value];
    }

    public override bool isDeclaration() {
        return false;
    }

    public override Flow evaluate(Runtime runtime) {
        return Evaluator.INSTANCE.evaluateAssignment(runtime, this);
    }

    public override string toString() {
        return format("Assignment(%s = %s)", target.toString(), value.toString());
    }
}

public enum BlockLimit : bool {
    START = true, END = false
}

public immutable class BlockNode : FlowNode {
    public FlowNode[] statements;
    public size_t exitOffset;
    public BlockLimit exitTarget;

    public this(immutable(FlowNode)[] statements, size_t start, size_t end) {
        this(statements, 0, BlockLimit.END, start, end);
    }

    public this(immutable(FlowNode)[] statements, size_t exitOffset, BlockLimit exitTarget, size_t start, size_t end) {
        inlineTrailingBlocks(statements, exitOffset, exitTarget);
        this.statements = statements;
        this.exitOffset = exitOffset;
        this.exitTarget = exitTarget;
        _start = start;
        _end = end;
    }

    mixin sourceIndexFields!false;

    public bool isConditional() {
        return false;
    }

    public override immutable(Node)[] getChildren() {
        return statements;
    }

    public override bool isDeclaration() {
        return any!(a => a.isDeclaration() || cast(immutable BlockNode) a !is null)(statements);
    }

    public override Flow evaluate(Runtime runtime) {
        return Evaluator.INSTANCE.evaluateBlock(runtime, this);
    }

    public override string toString() {
        return format("Block(%s)", statementsToString());
    }

    protected string statementsToString() {
        auto statementsString = statements.join!"; "();
        auto exitString = exitOffset != 0  || exitTarget != BlockLimit.END
                ? format("exit to %s of %s blocks", exitTarget, exitOffset) : "";
        if (statementsString.length > 0) {
            if (exitString.length > 0) {
                return format("%s; %s", statementsString, exitString);
            }
            return statementsString;
        }
        return exitString;
    }

    private static void inlineTrailingBlocks(ref immutable(FlowNode)[] statements, ref size_t exitOffset,
            ref BlockLimit exitTarget) {
        auto inlinedStatements = statements;
        auto nextIsUnreachable = false;
        foreach (i, statement; statements) {
            // Check if the statement was just marked as unreachable
            if (nextIsUnreachable) {
                throw new SourceException("Statement is unreachable", statement);
            }
            // Check if the statement is a nested block
            if (auto nestedBlock = cast(immutable BlockNode) statement) {
                // Ignore conditional ones since they don't always execute
                if (nestedBlock.isConditional()) {
                    continue;
                }
                // Ignore blocks that exit on themselves
                if (nestedBlock.exitOffset <= 0) {
                    continue;
                }
                // We can't inline blocks that contain declarations
                if (nestedBlock.isDeclaration()) {
                    continue;
                }
                // Change the exit information to be that of the nested block (correcting the offset for un-nesting)
                exitOffset = nestedBlock.exitOffset - 1;
                exitTarget = nestedBlock.exitTarget;
                // Inline the statements
                inlinedStatements = inlinedStatements[0 .. i] ~ nestedBlock.statements;
                // Mark all the other statements as unreachable;
                nextIsUnreachable = true;
            }
        }
        statements = inlinedStatements;
    }
}

public immutable class ConditionalBlockNode : BlockNode {
    public TypedNode condition;

    public this(immutable TypedNode condition, immutable FlowNode[] statements, size_t start, size_t end) {
        super(statements, start, end);
        this.condition = condition;
    }

    public this(immutable TypedNode condition, immutable FlowNode[] statements, size_t exitOffset, BlockLimit exitTarget,
            size_t start, size_t end) {
        super(statements, exitOffset, exitTarget, start, end);
        this.condition = condition;
    }

    public override bool isConditional() {
        return true;
    }

    public override immutable(Node)[] getChildren() {
        return cast(immutable Node) condition ~ cast(immutable(Node)[]) statements;
    }

    public override Flow evaluate(Runtime runtime) {
        return Evaluator.INSTANCE.evaluateConditionalBlock(runtime, this);
    }

    public override string toString() {
        return format("ConditionalBlock(if %s: %s)", condition.toString(), statementsToString());
    }
}

public immutable class FunctionDefinitionNode : FlowNode {
    public Function func;
    public Field[] parameters;
    public BlockNode implementation;

    public this(immutable Function func, immutable(Field)[] parameters, immutable BlockNode implementation,
            size_t start, size_t end) {
        assert (func.parameterTypes.length == parameters.length);
        this.func = func;
        this.parameters = parameters;
        this.implementation = implementation;
        _start = start;
        _end = end;
    }

    mixin sourceIndexFields!false;

    public override immutable(FlowNode)[] getChildren() {
        return [implementation];
    }

    public override bool isDeclaration() {
        return true;
    }

    public override Flow evaluate(Runtime runtime) {
        return Evaluator.INSTANCE.evaluateFunctionDefinition(runtime, this);
    }

    public override string toString() {
        return format("FunctionDefinition(%s(%s) %s: %s)", func.name, parameters.join!", "(), func.returnType.toString(),
                implementation.toString());
    }
}

public immutable class ReturnValueNode : FlowNode {
    public TypedNode value;

    public this(immutable TypedNode value, size_t start, size_t end) {
        this.value = value;
        _start = start;
        _end = end;
    }

    mixin sourceIndexFields!false;

    public override immutable(TypedNode)[] getChildren() {
        return [value];
    }

    public override bool isDeclaration() {
        return false;
    }

    public override Flow evaluate(Runtime runtime) {
        return Evaluator.INSTANCE.evaluateReturnValue(runtime, this);
    }

    public override string toString() {
        return format("Return(%s)", value.toString());
    }
}

public immutable class RuleNode : Node {
    public TypeDefinitionNode[] typeDefinitions;
    public FunctionDefinitionNode[] functionDefinitions;
    public VariableDeclarationNode[] variableDeclarations;

    public this(immutable(TypeDefinitionNode)[] typeDefinitions, immutable(FunctionDefinitionNode)[] functionDefinitions,
            immutable(VariableDeclarationNode)[] variableDeclarations, size_t start, size_t end) {
        this.typeDefinitions = typeDefinitions;
        this.functionDefinitions = functionDefinitions;
        this.variableDeclarations = variableDeclarations;
        _start = start;
        _end = end;
    }

    mixin sourceIndexFields!false;

    public override immutable(Node)[] getChildren() {
        immutable(Node)[] children;
        foreach (typeDef; typeDefinitions) {
            children ~= typeDef;
        }
        foreach (funcDef; functionDefinitions) {
            children ~= funcDef;
        }
        foreach (varDecl; variableDeclarations) {
            children ~= varDecl;
        }
        return children;
    }

    public void setupRuntime(Runtime runtime) {
        Evaluator.INSTANCE.setupRuntime(runtime, this);
    }

    public override string toString() {
        return format("Rule(%s)", getChildren().join!"; "());
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
    auto fromType = fromNode.getType();
    // Get the conversion chain from the node type to the parameter type
    auto conversions = new TypeConversionChain();
    bool convertible = fromType.specializableTo(toType, conversions);
    assert (convertible);
    // Wrap the node in casts based on the chain conversion type
    if (conversions.isIdentity() || conversions.isReferenceWidening()) {
        // Nothing to cast
        return fromNode;
    }
    if (conversions.isNumericWidening()) {
        // If the "from" node is a literal, use specialization instead of a cast
        auto fromLiteralNode = cast(immutable LiteralNode) fromNode;
        if (fromLiteralNode !is null) {
            return specializeNode(fromLiteralNode, toType);
        }
        // Add a call to the appropriate cast function
        auto castFunc = IntrinsicNameSpace.getExactFunctionStatic(toType.toString(), [fromType]);
        assert (castFunc !is null);
        return new immutable FunctionCallNode(castFunc, [fromNode], fromNode.start, fromNode.end);
    }
    if (conversions.isNumericNarrowing() || conversions.isReferenceNarrowing()) {
        // Must use specialization instead of a cast
        auto fromLiteralNode = cast(immutable LiteralNode) fromNode;
        assert (fromLiteralNode !is null);
        return specializeNode(fromLiteralNode, toType);
    }
    throw new SourceException(format("Unknown conversion chain from type %s to %s: %s",
            fromType.toString(), toType.toString(), conversions.toString()), fromNode);
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
    auto runtime = new Runtime();
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
    auto referenceType = cast(immutable ReferenceType) type;
    if (referenceType !is null) {
        auto sizedArrayType = cast(immutable SizedArrayType) type;
        if (sizedArrayType !is null) {
            auto defaultComponent = sizedArrayType.componentType.defaultValue(start, end);
            immutable(TypedNode)[] values;
            immutable(ArrayLabel)[] labels;
            if (sizedArrayType.size > 0) {
                values ~= defaultComponent;
                labels ~= immutable ArrayLabel(sizedArrayType.size - 1, start, end);
            }
            values ~= defaultComponent;
            labels ~= ArrayLabel.asOther(start, end);
            return new immutable ArrayLiteralNode(values, labels, start, end);
        }
        return new immutable NullLiteralNode(start, end);
    }
    throw new Exception(format("No default value for type %s", type.toString()));
}
