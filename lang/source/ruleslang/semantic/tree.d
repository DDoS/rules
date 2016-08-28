module ruleslang.semantic.tree;

import std.conv : to;
import std.algorithm.searching;
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
        if (AtomicType.BOOL.isEquivalent(specialType)) {
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

public immutable class StringLiteralNode : LiteralNode {
    private StringLiteralType type;
    private CompositeInfo info;

    public this(dstring value) {
        type = new immutable StringLiteralType(value);
        info = type.compositeInfo();
    }

    public override immutable(TypedNode)[] getChildren() {
        return [];
    }

    public override immutable(StringLiteralType) getType() {
        return type;
    }

    public immutable(CompositeInfo) getCompositeInfo() {
        return info;
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
    public AtomicType specialType;

    public this(long value) {
        auto type = new immutable SignedIntegerLiteralType(value);
        this(type, AtomicType.SINT64);
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
                return new immutable FloatLiteralNode(type.value).specializeTo(specialType);
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
        return format("SignedIntegerLiteral(%s %d)", specialType.toString(), type.value);
    }
}

public immutable class UnsignedIntegerLiteralNode : LiteralNode {
    private UnsignedIntegerLiteralType type;
    public AtomicType specialType;

    public this(ulong value) {
        auto type = new immutable UnsignedIntegerLiteralType(value);
        this(type, AtomicType.UINT64);
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
                return new immutable FloatLiteralNode(type.value).specializeTo(specialType);
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
        return format("UnsignedIntegerLiteral(%s %d)", specialType.toString(), type.value);
    }
}

public immutable class FloatLiteralNode : LiteralNode {
    private FloatLiteralType type;
    public AtomicType specialType;

    public this(double value) {
        auto type = new immutable FloatLiteralType(value);
        this(type, AtomicType.FP64);
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
            return new immutable FloatLiteralNode(type, atomicSpecial);
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
        return format("FloatLiteral(%s %g)", specialType.toString(), type.value);
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

public immutable class TupleLiteralNode : LiteralNode {
    private TypedNode[] values;
    private TupleLiteralType type;

    public this(immutable(TypedNode)[] values) {
        this.values = values.reduceLiterals();
        this.type = new immutable TupleLiteralType(this.values.getTypes());
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

public immutable class StructLiteralNode : LiteralNode {
    private TypedNode[] values;
    private string[] labels;
    private StructureLiteralType type;

    public this(immutable(TypedNode)[] values, immutable(string)[] labels) {
        assert(values.length > 0);
        assert(values.length == labels.length);
        this.values = values.reduceLiterals();
        this.labels = labels;
        type = new immutable StructureLiteralType(this.values.getTypes(), labels);
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

public immutable class ArrayLiteralNode : LiteralNode {
    private TypedNode[] values;
    private ArrayLabel[] labels;
    private SizedArrayLiteralType type;

    public this(immutable(TypedNode)[] values, immutable(ArrayLabel)[] labels) {
        assert(values.length > 0);
        assert(values.length == labels.length);
        this.values = values.reduceLiterals();
        this.labels = labels;
        // The array size if the max index label plus one
        ulong maxIndex = 0;
        foreach (label; labels) {
            if (!label.other && label.index > maxIndex) {
                maxIndex = label.index;
            }
        }
        type = new immutable SizedArrayLiteralType(this.values.getTypes(), maxIndex + 1);
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
        auto compositeType = cast(immutable CompositeType) this.valueNode.getType();
        assert (compositeType !is null);
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
            type = compositeType.getMemberType(index);
            if (type is null) {
                throw new Exception(format("Index %d is out of range of composite %s", index, compositeType.toString()));
            }
            return;
        }
        // Otherwise, for an array type, just use the component type
        auto arrayType = cast(immutable ArrayType) compositeType;
        if (arrayType !is null) {
            type = arrayType.componentType;
            return;
        }
        throw new Exception(format("Index must be known at compile time for type %s", compositeType.toString()));
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
            return new immutable FloatLiteralNode(value.get!double());
        }
        if (atomicType.isInteger()) {
            if (atomicType.isSigned()) {
                return new immutable SignedIntegerLiteralNode(value.get!long());
            }
            return new immutable UnsignedIntegerLiteralNode(value.get!ulong());
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
