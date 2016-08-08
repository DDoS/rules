module ruleslang.evaluation.value;

import std.conv : to;

import ruleslang.util;

public immutable union Value {
    private long data;
    private float floatView;
    private double doubleView;

    private this(long data) {
        this.data = data;
    }

    private this(float value) {
        floatView = value;
    }

    private this(double value) {
        doubleView = value;
    }

    @property public T as(T)() if (isAtomicIntegerType!T) {
        return cast(T) data;
    }

    @property public T as(T : float)() if (!isAtomicIntegerType!T) {
        return floatView;
    }

    @property public T as(T : double)() if (!isAtomicIntegerType!T) {
        return doubleView;
    }

    public string toString() {
        return data.to!string;
    }

    public bool opEquals(inout Value other) {
        return data == other.data;
    }
}

public immutable(Value) valueOf(T)(T value) if (isAtomicIntegerType!T) {
    return immutable Value(cast(long) value);
}

public immutable(Value) valueOf(T : float)(T value) if (!isAtomicIntegerType!T) {
    return immutable Value(value);
}

public immutable(Value) valueOf(T : double)(T value) if (!isAtomicIntegerType!T) {
    return immutable Value(value);
}

private bool isAtomicIntegerType(T)() {
    static if (is(T : bool) || is(T : byte) || is(T : ubyte) || is(T : short) || is(T : ushort)
            || is(T : int) || is(T : uint) || is(T : long) || is(T : ulong)) {
        return true;
    } else {
        return false;
    }
}
