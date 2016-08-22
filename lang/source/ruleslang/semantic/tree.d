module ruleslang.semantic.tree;

import std.conv : to;
import std.format : format;

import ruleslang.semantic.type;
import ruleslang.semantic.symbol;
import ruleslang.semantic.context;
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
        this.values = values;
        this.type = new immutable TupleLiteralType(values.getTypes());
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

public immutable class StructLiteralNode : TypedNode {
    private TypedNode[] values;
    private string[] labels;
    private Type type;

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

    public override immutable(Type) getType() {
        return type;
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

    public override string toString() {
        return format("FunctionCall(%s(%s))", func.name(), arguments.join!", "());
    }
}

private immutable(TypedNode) addCastNode(immutable TypedNode fromNode, immutable Type toType) {
    auto fromType = fromNode.getType();
    // Get the conversion chain from the node type to the parameter type
    auto fromLiteralType = cast(immutable LiteralType) fromType;
    auto conversions = new TypeConversionChain();
    if (fromLiteralType !is null) {
        bool convertible = fromLiteralType.specializableTo(toType, conversions);
        assert (convertible);
    } else {
        bool convertible = fromType.convertibleTo(toType, conversions);
        assert (convertible);
    }
    // Wrap the node in casts based on the chain conversion type
    if (conversions.isIdentity() || conversions.isReferenceWidening()) {
        // Nothing to cast
        return fromNode;
    }
    if (conversions.isNumeric()) {
        // Add a call to the appropriate cast function
        auto argType = fromLiteralType !is null ? fromLiteralType.getBackingType() : fromType;
        auto castFunc = IntrinsicNameSpace.INSTANCE.getExactFunction(toType.toString(), [argType]);
        assert (castFunc !is null);
        return new immutable FunctionCallNode(castFunc, [fromNode]);
    }
    // TODO: other cast types
    throw new Exception(format("Unknown conversion chain from type %s to %s: %s",
            fromType.toString(), toType.toString(), conversions.toString()));
}
