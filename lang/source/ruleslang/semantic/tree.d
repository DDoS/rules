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

public immutable class BooleanLiteralNode : TypedNode {
    private bool _value;

    public this(bool value) {
        _value = value;
    }

    public override Node[] getChildren() {
        return [];
    }

    public override immutable(Type) getType() {
        return AtomicType.BOOL;
    }

    public override string toString() {
        return format("BooleanLiteral(%s)", _value);
    }
}

public immutable class StringLiteralNode : TypedNode {
    private dstring _value;
    private StringLiteralType type;

    public this(dstring value) {
        _value = value;
        type = new immutable StringLiteralType(value);
    }

    public override Node[] getChildren() {
        return [];
    }

    public override immutable(Type) getType() {
        return type;
    }

    public override string toString() {
        return format("StringLiteral(%s)", _value);
    }
}

public immutable class SignedIntegerLiteralNode : TypedNode {
    private long _value;
    private SignedIntegerLiteralType type;

    public this(long value) {
        _value = value;
        type = new immutable SignedIntegerLiteralType(value);
    }

    public override Node[] getChildren() {
        return [];
    }

    public override immutable(Type) getType() {
        return type;
    }

    public override string toString() {
        return format("SignedIntegerLiteral(%d)", _value);
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
