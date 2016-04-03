module ruleslang.semantic.tree;

import std.format : format;

import ruleslang.semantic.type;

public immutable interface Node {
    public Node[] getChildren();
    public string toString();
}

public immutable interface TypedNode : Node {
    public immutable(Type) getType();
}

public immutable class NullNode : Node {
    public static immutable NullNode INSTANCE = new immutable NullNode();

    private this() {
    }

    public override Node[] getChildren() {
        return [];
    }

    public override string toString() {
        return "NullNode()";
    }
}

public immutable class SignedIntegerLiteralNode : TypedNode {
    public override Node[] getChildren() {
        return [];
    }

    public override immutable(Type) getType() {
        return AtomicType.UINT8;
    }

    public override string toString() {
        return "";
    }
}

public immutable class UnsignedIntegerLiteralNode : TypedNode {
    private ulong _value;
    private UnsignedIntegerLiteralType type;

    public this(ulong value) {
        _value = value;
        type = new immutable UnsignedIntegerLiteralType(value);
    }

    public override Node[] getChildren() {
        return [];
    }

    public override immutable(Type) getType() {
        return type;
    }

    public override string toString() {
        return format("UnsignedIntegerLiteral(%d)", _value);
    }
}

public immutable class FloatLiteralNode : TypedNode {
    private double _value;
    private FloatLiteralType type;

    public this(double value) {
        _value = value;
        type = new immutable FloatLiteralType(value);
    }

    public override Node[] getChildren() {
        return [];
    }

    public override immutable(Type) getType() {
        return type;
    }

    public override string toString() {
        return format("FloatLiteral(%g)", _value);
    }
}
