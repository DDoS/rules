module ruleslang.semantic.tree;

import std.conv : to;
import std.format : format;

import ruleslang.semantic.type;
import ruleslang.semantic.symbol;
import ruleslang.util;

public immutable interface Node {
    public immutable(Node)[] getChildren();
    public string toString();
}

public immutable interface TypedNode : Node {
    public immutable(TypedNode)[] getChildren();
    public immutable(Type) getType();
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

    public override string toString() {
        return "Null()";
    }
}

public immutable class BooleanLiteralNode : TypedNode {
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

    public override string toString() {
        return format("BooleanLiteral(%s)", type.value);
    }
}

public immutable class StringLiteralNode : TypedNode {
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

    public override string toString() {
        return format("StringLiteral(\"%s\")", type.value);
    }
}

public immutable class SignedIntegerLiteralNode : TypedNode {
    private SignedIntegerLiteralType type;

    public this(long value) {
        type = new immutable SignedIntegerLiteralType(value);
    }

    public override immutable(TypedNode)[] getChildren() {
        return [];
    }

    public override immutable(SignedIntegerLiteralType) getType() {
        return type;
    }

    public override string toString() {
        return format("SignedIntegerLiteral(%d)", type.value);
    }
}

public immutable class UnsignedIntegerLiteralNode : TypedNode {
    private UnsignedIntegerLiteralType type;

    public this(long value) {
        type = new immutable UnsignedIntegerLiteralType(value);
    }

    public override immutable(TypedNode)[] getChildren() {
        return [];
    }

    public override immutable(UnsignedIntegerLiteralType) getType() {
        return type;
    }

    public override string toString() {
        return format("UnsignedIntegerLiteral(%d)", type.value);
    }
}

public immutable class FloatLiteralNode : TypedNode {
    private FloatLiteralType type;

    public this(double value) {
        type = new immutable FloatLiteralType(value);
    }

    public override immutable(TypedNode)[] getChildren() {
        return [];
    }

    public override immutable(FloatLiteralType) getType() {
        return type;
    }

    public override string toString() {
        return format("FloatLiteral(%g)", type.value);
    }
}

public immutable class EmptyLiteralNode : TypedNode {
    public static immutable EmptyLiteralNode INSTANCE = new immutable EmptyLiteralNode();

    private this() {
    }

    public override immutable(TypedNode)[] getChildren() {
        return [];
    }

    public override immutable(Type) getType() {
        return AnyType.INSTANCE;
    }

    public override string toString() {
        return "EmptyLiteralNode({})";
    }
}

public immutable class TupleLiteralNode : TypedNode {
    private TypedNode[] values;
    private Type type;

    public this(immutable(TypedNode)[] values) {
        assert (values.length > 0);
        this(values, new immutable TupleType(values.getTypes()));
    }

    private this(immutable(TypedNode)[] values, immutable Type type) {
        this.values = values;
        this.type = type;
    }

    public override immutable(TypedNode)[] getChildren() {
        return values;
    }

    public override immutable(Type) getType() {
        return type;
    }

    public override string toString() {
        return format("TupleLiteral({%s})", values.join!", "());
    }
}

public immutable class StructLiteralNode : TupleLiteralNode {
    private string[] labels;

    public this(immutable(TypedNode)[] values, string[] labels) {
        assert(values.length > 0);
        this.labels = labels.idup;
        super(values, new immutable StructureType(values.getTypes(), this.labels));
    }

    public override string toString() {
        return format("StructLiteral({%s})", stringZip!": "(labels, values).join!", "());
    }
}

private immutable(Type)[] getTypes(immutable(TypedNode)[] values) {
    immutable(Type)[] valueTypes = [];
    foreach (value; values) {
        valueTypes ~= value.getType();
    }
    return valueTypes;
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

public immutable class ArrayLiteralNode : TupleLiteralNode {
    private ArrayLabel[] labels;
    private SizedArrayType type;

    public this(immutable(TypedNode)[] values, immutable(ArrayLabel)[] labels) {
        assert(values.length > 0);
        assert(values.length == labels.length);
        super(values);
        this.labels = labels.idup;
        // The component type is the lowest upper bound of the components
        auto firstType = values[0].getType();
        immutable(Type)* componentType = &firstType;
        foreach (value; values[1 .. $]) {
            auto lub = (*componentType).lowestUpperBound(value.getType());
            if (lub is null) {
                throw new Exception(format("No common supertype for %s and %s",
                        (*componentType).toString(), value.getType().toString()));
            }
            componentType = &lub;
        }
        // The array size if the max index label plus one
        ulong maxIndex = 0;
        foreach (label; labels) {
            if (!label.other() && label.index > maxIndex) {
                maxIndex = label.index;
            }
        }
        type = new immutable SizedArrayType(*componentType, maxIndex + 1);
    }

    public override immutable(SizedArrayType) getType() {
        return type;
    }

    public override string toString() {
        return format("ArrayLiteral({%s})", stringZip!": "(labels, values).join!", "());
    }
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

    public override string toString() {
        return format("MemberAccess(%s(%s))", value.toString(), name);
    }
}

public immutable class ArrayIndexNode : TypedNode {
    private TypedNode valueNode;
    private TypedNode indexNode;
    private Type type;

    public this(immutable TypedNode valueNode, immutable TypedNode indexNode) {
        this.valueNode = valueNode;
        this.indexNode = indexNode;
        auto arrayType = cast(immutable ArrayType) valueNode.getType();
        assert (arrayType !is null);
        auto stringType = cast(immutable StringLiteralType) arrayType;
        if (stringType !is null) {
            auto integerLiteralIndex = cast(immutable IntegerLiteralType) indexNode.getType();
            if (integerLiteralIndex !is null) {
                auto index = integerLiteralIndex.unsignedValue();
                auto str = stringType.value;
                if (index >= str.length) {
                    throw new Exception(format("Index value %d is out of range of string \"%s\"", index, str));
                }
                type = new immutable UnsignedIntegerLiteralType(str[index]);
                return;
            }
        }
        type = arrayType.componentType();
    }

    public override immutable(TypedNode)[] getChildren() {
        return [valueNode, indexNode];
    }

    public override immutable(Type) getType() {
        return type;
    }

    public override string toString() {
        return format("ArrayAccess(%s[%s]))", valueNode.toString(), indexNode.toString());
    }
}

public immutable class FunctionCallNode : TypedNode {
    private Function func;
    private TypedNode[] arguments;

    public this(immutable Function func, immutable(TypedNode)[] arguments) {
        this.func = func;
        this.arguments = arguments;
    }

    public override immutable(TypedNode)[] getChildren() {
        return arguments;
    }

    public override immutable(Type) getType() {
        return func.returnType();
    }

    public override string toString() {
        return format("FunctionCall(%s(%s))", func.name(), arguments.join!", "());
    }
}
