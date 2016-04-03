module ruleslang.semantic.tree;

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
