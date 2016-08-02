module ruleslang.semantic.function_;

import std.conv : to;

import ruleslang.semantic.type;
import ruleslang.util;

public immutable class Function {
    private string _name;
    private Type[] _argumentTypes;
    private Type _returnType;

    public this(string name, immutable Type returnType, immutable Type[] argumentTypes...) {
        _name = name;
        _returnType = returnType;
        _argumentTypes = argumentTypes;
    }

    @property public string name() {
        return _name;
    }

    @property public immutable(Type[]) argumentTypes() {
        return _argumentTypes;
    }

    @property public immutable(Type) returnType() {
        return _returnType;
    }

    public bool isOverload(immutable Function other) {
        return _name == other.name && _argumentTypes != other.argumentTypes;
    }

    public bool isMoreSpecific(immutable Function other) {
        if (_argumentTypes.length != other.argumentTypes.length) {
            throw new Exception("Expected " ~ _argumentTypes.length.to!string ~ " argument types");
        }
        // Compare argument types pairwise
        // No type can be larger than in other
        // At least one type must be smaller than in other
        auto oneSmaller = false;
        foreach (i, thisType; _argumentTypes) {
            auto otherType = other.argumentTypes[i];
            auto thisChain = new TypeConversionChain();
            auto otherChain = new TypeConversionChain();
            auto thisSmaller = thisType.convertibleTo(otherType, otherChain);
            auto otherSmaller = otherType.convertibleTo(thisType, thisChain);
            if (otherSmaller && !thisSmaller) {
                return false;
            }
            assert(thisChain.length <= otherChain.length);
            if (thisSmaller && !otherSmaller) {
                oneSmaller = true;
            }
        }
        return oneSmaller;
    }

    public string toString() {
        return name ~ "(" ~ _argumentTypes.join!", "() ~ ") " ~ _returnType.toString();
    }

    public bool opEquals(immutable Function other) {
        return _name == other.name && _argumentTypes == other.argumentTypes;
    }
}
