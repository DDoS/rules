module ruleslang.semantic.type;

import std.format : format;
import std.algorithm.searching : canFind;
import std.exception : assumeUnique;
import std.math: isNaN, isInfinity;

import ruleslang.util;

public immutable interface Type {
    public bool convertibleTo(inout Type type);
    public string toString();
}

public immutable class AtomicType : Type {
    public static immutable AtomicType BOOL = new immutable AtomicType("bool", 1, false, false);
    public static immutable AtomicType SINT8 = new immutable AtomicType("sint8", 8, true, false);
    public static immutable AtomicType UINT8 = new immutable AtomicType("uint8", 8, false, false);
    public static immutable AtomicType SINT16 = new immutable AtomicType("sint16", 16, true, false);
    public static immutable AtomicType UINT16 = new immutable AtomicType("uint16", 16, false, false);
    public static immutable AtomicType SINT32 = new immutable AtomicType("sint32", 32, true, false);
    public static immutable AtomicType UINT32 = new immutable AtomicType("uint32", 32, false, false);
    public static immutable AtomicType SINT64 = new immutable AtomicType("sint64", 64, true, false);
    public static immutable AtomicType UINT64 = new immutable AtomicType("uint64", 64, false, false);
    public static immutable AtomicType FP16 = new immutable AtomicType("fp16", 16, true, true);
    public static immutable AtomicType FP32 = new immutable AtomicType("fp32", 32, true, true);
    public static immutable AtomicType FP64 = new immutable AtomicType("fp64", 64, true, true);
    private static immutable immutable(AtomicType)[][immutable(AtomicType)] CONVERSIONS;
    private static immutable immutable(AtomicType)[] INTEGERS = [
        SINT8, UINT8, SINT16, UINT16, SINT32, UINT32, SINT64, UINT64
    ];
    private string name;
    private uint bitCount;
    private bool signed;
    private bool fp;

    public static this() {
        immutable(AtomicType)[][immutable(AtomicType)] subtypes = [
            BOOL: [],
            SINT8: [SINT16],
            UINT8: [UINT16, SINT16],
            SINT16: [SINT32, FP16],
            UINT16: [UINT32, SINT32, FP16],
            SINT32: [SINT64, FP32],
            UINT32: [UINT64, SINT64, FP32],
            SINT64: [FP64],
            UINT64: [FP64],
            FP16: [FP32],
            FP32: [FP64],
            FP64: []
        ];
        auto conv = subtypes.transitiveClosure();
        conv.rehash;
        CONVERSIONS = conv.assumeUnique();
    }

    private this(string name, uint bitCount, bool signed, bool fp) {
        this.name = name;
        this.bitCount = bitCount;
        this.signed = signed;
        this.fp = fp;
    }

    public bool isBoolean() {
        return bitCount == 1;
    }

    public bool isInteger() {
        return bitCount > 1 && !fp;
    }

    public bool isSigned() {
        return signed;
    }

    public bool isFloat() {
        return fp;
    }

    public bool inRange(T)(T value) if (!__traits(isIntegral, T) || !__traits(isFloating, T)) {
        // Signed int
        if (signed && !fp) {
            static if (__traits(isFloating, T)) {
                return false;
            } else {
                return cast(long) value >= (cast(long) -1 << (bitCount - 1)) && value <= (cast(long) -1 >>> (65 - bitCount));
            }
        }
        // Unsigned int
        if (!fp) {
            static if (__traits(isFloating, T)) {
                return false;
            } else {
                return value >= 0 && value <= (cast(ulong) -1 >>> (64 - bitCount));
            }
        }
        // Float
        static if (__traits(isFloating, T)) {
            if (isNaN(value) || isInfinity(value)) {
                return true;
            }
        }
        final switch (bitCount) {
            case 16:
                return value >= -65504.0f && value <= 65504.0f;
            case 32:
                return value >= -0x1.fffffeP+127f && value <= 0x1.fffffeP+127f;
            case 64:
                return value >= -0x1.fffffffffffffP+1023 && value <= 0x1.fffffffffffffP+1023;
        }
    }

    public override bool convertibleTo(inout Type type) {
        auto atomic = cast(immutable(AtomicType)) type;
        if (atomic is null) {
            return false;
        }
        return CONVERSIONS[this].canFind(atomic);
    }

    public override string toString() {
        return name;
    }
}

public immutable class SignedIntegerLiteralType : Type {
    private long _value;

    public this(long value) {
        _value = value;
    }

    @property public long value() {
        return _value;
    }

    public override bool convertibleTo(inout Type type) {
        if (cast(immutable(SignedIntegerLiteralType)) type) {
            return true;
        }
        auto atomic = cast(immutable(AtomicType)) type;
        if (atomic is null) {
            return false;
        }
        return atomic.isInteger() && atomic.inRange(value);
    }

    public override string toString() {
        return format("lit_sint64(%d)", _value);
    }
}

public immutable class UnsignedIntegerLiteralType : Type {
    private ulong _value;

    public this(ulong value) {
        _value = value;
    }

    @property public ulong value() {
        return _value;
    }

    public override bool convertibleTo(inout Type type) {
        if (cast(immutable(UnsignedIntegerLiteralType)) type) {
            return true;
        }
        auto atomic = cast(immutable(AtomicType)) type;
        if (atomic is null) {
            return false;
        }
        return atomic.isInteger() && atomic.inRange(_value);
    }

    public override string toString() {
        return format("lit_uint64(%d)", _value);
    }
}

public immutable class FloatLiteralType : Type {
    private double _value;

    public this(double value) {
        _value = value;
    }

    @property public double value() {
        return _value;
    }

    public override bool convertibleTo(inout Type type) {
        if (cast(immutable(FloatLiteralType)) type) {
            return true;
        }
        auto atomic = cast(immutable(AtomicType)) type;
        if (atomic is null) {
            return false;
        }
        return atomic.isFloat() && atomic.inRange(_value);
    }

    public override string toString() {
        return format("lit_fp64(%g)", _value);
    }
}
