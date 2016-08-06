module ruleslang.evaluation.value;

public immutable interface Value {
    public byte asByte();
    public ubyte asUByte();
    public short asShort();
    public ushort asUShort();
    public int asInt();
    public uint asUInt();
    public long asLong();
    public ulong asULong();
    public float asFloat();
    public double asDouble();
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

public immutable class AtomicValue(T) : Value {
    private T _value;

    public this(T value) {
        _value = value;
    }

    @property public T value() {
        return _value;
    }

    public override byte asByte() {
        return cast(byte) _value;
    }

    public override ubyte asUByte() {
        return cast(ubyte) _value;
    }

    public override short asShort() {
        return cast(short) _value;
    }

    public override ushort asUShort() {
        return cast(ushort) _value;
    }

    public override int asInt() {
        return cast(int) _value;
    }

    public override uint asUInt() {
        return cast(uint) _value;
    }

    public override long asLong() {
        return cast(long) _value;
    }

    public override ulong asULong() {
        return cast(ulong) _value;
    }

    public override float asFloat() {
        return cast(float) _value;
    }

    public override double asDouble() {
        return cast(double) _value;
    }
}
