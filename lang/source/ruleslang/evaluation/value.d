module ruleslang.evaluation.value;

import std.conv : to;

import ruleslang.util;

public immutable interface Value {
    public string toString();
    public bool opEquals(inout Value value);
}

public alias ByteValue = AtomicValue!byte;
public alias UByteValue = AtomicValue!ubyte;
public alias ShortValue = AtomicValue!short;
public alias UShortValue = AtomicValue!ushort;
public alias IntValue = AtomicValue!int;
public alias UIntValue = AtomicValue!uint;
public alias LongValue = AtomicValue!long;
public alias ULongValue = AtomicValue!ulong;
public alias FloatValue = AtomicValue!float;
public alias DoubleValue = AtomicValue!double;

public immutable class AtomicValue(T) : Value if (isAtomicType!T) {
    private T _value;

    public this(T value) {
        _value = value;
    }

    @property public T value() {
        return _value;
    }

    public S valueAs(S)() {
        return cast(S) _value;
    }

    public immutable(AtomicValue!T) asValue(T)() if (isAtomicType!T) {
        return AtomicValue!T.fromCast(_value);
    }

    public immutable(Value) applyUnary(string operator)() {
        return from(mixin(operator ~ "_value"));
    }

    public immutable(Value) applyBinary(string operator, S)(immutable AtomicValue!S other) {
        return from(mixin("_value " ~ operator ~ " other.value"));
    }

    public override string toString() {
        return _value.to!string;
    }

    public override bool opEquals(inout Value value) {
        auto atomic = value.exactCastImmutable!(AtomicValue!T);
        return atomic !is null && _value == atomic.value;
    }

    public static immutable(AtomicValue!T) fromCast(S)(S s) if (isAtomicType!S) {
        return new immutable AtomicValue!T(cast(T) s);
    }
}

public immutable(AtomicValue!T) from(T)(T value) if (isAtomicType!T) {
    return new immutable AtomicValue!T(value);
}

private bool isAtomicType(T)() {
    static if (is(T : byte) || is(T : ubyte) || is(T : short) || is(T : ushort) || is(T : int)
            || is(T : uint) || is(T : long) || is(T : ulong) || is(T : float) || is(T : double)) {
        return true;
    } else {
        return false;
    }
}
