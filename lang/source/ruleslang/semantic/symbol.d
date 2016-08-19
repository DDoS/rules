module ruleslang.semantic.symbol;

import std.conv : to;

import ruleslang.semantic.type;
import ruleslang.evaluation.value;
import ruleslang.util;

public immutable interface Symbol {
    @property public string name();
}

public immutable class Field : Symbol {
    private string _name;
    private Type _type;

    public this(string name, immutable Type type) {
        _name = name;
        _type = type;
    }

    @property public override string name() {
        return _name;
    }

    @property public immutable(Type) type() {
        return _type;
    }

    public string toString() {
        return _type.toString() ~ " " ~ _name;
    }

    public bool opEquals(immutable Field other) {
        return _name == other.name;
    }
}

public immutable class Function : Symbol {
    private string _name;
    private Type[] _parameterTypes;
    private Type _returnType;

    public this(string name, immutable(Type)[] parameterTypes, immutable Type returnType) {
        _name = name;
        _returnType = returnType;
        _parameterTypes = parameterTypes;
    }

    @property public override string name() {
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

    public alias areConvertible = areApplicable!("convertibleTo", Type);
    public alias areSpecializable = areApplicable!("specializableTo", LiteralType);

    private bool areApplicable(string test, T : Type)(immutable(T)[] argumentTypes) {
        if (_parameterTypes.length != argumentTypes.length) {
            return false;
        }
        foreach (i, arg; _parameterTypes) {
            auto chain = new TypeConversionChain();
            if (!mixin("argumentTypes[i]." ~ test ~ "(arg, chain)")) {
                return false;
            }
        }
        return true;
    }

    public alias isMoreSpecific = testSpecificity!true;
    public alias isLessSpecific = testSpecificity!false;

    public bool testSpecificity(bool more)(immutable Function other) {
        if (_parameterTypes.length != other.parameterTypes.length) {
            throw new Error("Expected " ~ _parameterTypes.length.to!string ~ " argument types");
        }
        // Compare argument types pairwise
        // No type can be worst than in other
        // At least one type must be better than in other
        auto oneBetter = false;
        foreach (i, thisType; _parameterTypes) {
            auto otherType = other.parameterTypes[i];
            auto thisChain = new TypeConversionChain();
            auto otherChain = new TypeConversionChain();
            static if (more) {
                auto thisBetter = thisType.convertibleTo(otherType, thisChain);
                auto otherBetter = otherType.convertibleTo(thisType, otherChain);
            } else {
                auto thisBetter = otherType.convertibleTo(thisType, thisChain);
                auto otherBetter = thisType.convertibleTo(otherType, otherChain);
            }
            if (otherBetter && !thisBetter) {
                return false;
            }
            if (thisBetter && !otherBetter) {
                oneBetter = true;
            }
        }
        return oneBetter;
    }

    public string toString() {
        return _name ~ "(" ~ _parameterTypes.join!", "() ~ ") " ~ _returnType.toString();
    }

    public bool opEquals(immutable Function other) {
        return _name == other.name && _parameterTypes == other.parameterTypes;
    }
}
