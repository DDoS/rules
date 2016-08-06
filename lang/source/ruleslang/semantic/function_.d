module ruleslang.semantic.function_;

import std.conv : to;

import ruleslang.semantic.type;
import ruleslang.util;

public immutable class Function {
    private string _name;
    private Type[] _parameterTypes;
    private Type _returnType;

    public this(string name, immutable Type[] parameterTypes, immutable Type returnType) {
        _name = name;
        _returnType = returnType;
        _parameterTypes = parameterTypes;
    }

    @property public string name() {
        return _name;
    }

    @property public immutable(Type[]) parameterTypes() {
        return _parameterTypes;
    }

    @property public immutable(Type) returnType() {
        return _returnType;
    }

    public bool isOverload(immutable Function other) {
        return _name == other.name && _parameterTypes != other.parameterTypes;
    }

    public bool isApplicable(immutable(Type)[] argumentTypes) {
        if (_parameterTypes.length != argumentTypes.length) {
            return false;
        }
        foreach (i, arg; _parameterTypes) {
            auto chain = new TypeConversionChain();
            if (!argumentTypes[i].convertibleTo(arg, chain)) {
                return false;
            }
        }
        return true;
    }

    public bool isMoreSpecific(immutable Function other) {
        if (_parameterTypes.length != other.parameterTypes.length) {
            throw new Error("Expected " ~ _parameterTypes.length.to!string ~ " argument types");
        }
        // Compare argument types pairwise
        // No type can be larger than in other
        // At least one type must be smaller than in other
        auto oneSmaller = false;
        foreach (i, thisType; _parameterTypes) {
            auto otherType = other.parameterTypes[i];
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
        return name ~ "(" ~ _parameterTypes.join!", "() ~ ") " ~ _returnType.toString();
    }

    public bool opEquals(immutable Function other) {
        return _name == other.name && _parameterTypes == other.parameterTypes;
    }
}
