module ruleslang.semantic.type;

import std.format : format;
import std.algorithm.searching : canFind;
import std.exception : assumeUnique;
import std.math: isNaN, isInfinity;

import ruleslang.util;

public immutable interface Type {
    public bool convertibleTo(inout Type type);
    public string toString();
    public bool opEquals(inout Type type);
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
        auto atomic = cast(immutable AtomicType) type;
        if (atomic is null) {
            return false;
        }
        return CONVERSIONS[this].canFind(atomic);
    }

    public override string toString() {
        return name;
    }

    public override bool opEquals(inout Type type) {
        auto atomicType = cast(immutable AtomicType) type;
        if (atomicType is null || typeid(atomicType) != typeid(AtomicType)) {
            return false;
        }
        return bitCount == atomicType.bitCount && signed == atomicType.signed &&
                fp == atomicType.fp;
    }
}

private mixin template literalTypeOpEquals(L) {
    public override bool opEquals(inout Type type) {
        auto literalType = cast(immutable L) type;
        if (literalType is null || typeid(literalType) != typeid(L)) {
            return false;
        }
        return _value == literalType._value;
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
        if (opEquals(type)) {
            return true;
        }
        auto atomic = cast(immutable AtomicType) type;
        if (atomic is null) {
            return false;
        }
        return atomic.isInteger() && atomic.inRange(_value);
    }

    public override string toString() {
        return format("lit_sint64(%d)", _value);
    }

    mixin literalTypeOpEquals!SignedIntegerLiteralType;
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
        if (opEquals(type)) {
            return true;
        }
        auto atomic = cast(immutable AtomicType) type;
        if (atomic is null) {
            return false;
        }
        return atomic.isInteger() && atomic.inRange(_value);
    }

    public override string toString() {
        return format("lit_uint64(%d)", _value);
    }

    mixin literalTypeOpEquals!UnsignedIntegerLiteralType;
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
        if (opEquals(type)) {
            return true;
        }
        auto atomic = cast(immutable AtomicType) type;
        if (atomic is null) {
            return false;
        }
        return atomic.isFloat() && atomic.inRange(_value);
    }

    public override string toString() {
        return format("lit_fp64(%g)", _value);
    }

    mixin literalTypeOpEquals!FloatLiteralType;
}

public immutable class ArrayType : Type {
    private Type _componentType;
    private uint _totalDepth;

    public this(immutable Type componentType) {
        _componentType = componentType;
        // Include depth of component type
        auto depth = 1;
        auto arrayComponentType = cast(immutable ArrayType) componentType;
        if (arrayComponentType !is null) {
            depth += arrayComponentType.totalDepth;
        }
        _totalDepth = depth;
    }

    @property public immutable(Type) componentType() {
        return _componentType;
    }

    @property public uint totalDepth() {
        return _totalDepth;
    }

    public override bool convertibleTo(inout Type type) {
        // Only identity conversion is allowed
        return opEquals(type);
    }

    public override string toString() {
        return format("%s[]", _componentType.toString());
    }

    public override bool opEquals(inout Type type) {
        auto arrayType = cast(immutable ArrayType) type;
        if (arrayType is null || typeid(arrayType) != typeid(ArrayType)) {
            return false;
        }
        return arrayType.totalDepth == _totalDepth && arrayType.componentType == _componentType;
    }
}

public immutable class SizedArrayType : ArrayType {
    private ulong _size;

    public this(immutable Type componentType, ulong size) {
        super(componentType);
        _size = size;
    }

    @property public ulong size() {
        return _size;
    }

    public override bool convertibleTo(inout Type type) {
        // If the sized array has size 1, we can interpret it as its component type
        if (_size == 1 && componentType.convertibleTo(type)) {
            return true;
        }
        auto arrayType = cast(immutable ArrayType) type;
        if (arrayType is null) {
            return false;
        }
        // Can cast to unsized if the component and depth match
        if (arrayType.totalDepth != totalDepth || arrayType.componentType != componentType) {
            return false;
        }
        // If the array is sized then the length must be smaller or equal
        auto sizedArrayType = cast(immutable SizedArrayType) arrayType;
        return sizedArrayType is null || _size >= sizedArrayType.size;
    }

    public override string toString() {
        return format("%s[%d]", componentType.toString(), _size);
    }

    public override bool opEquals(inout Type type) {
        auto arrayType = cast(immutable SizedArrayType) type;
        if (arrayType is null || typeid(arrayType) != typeid(SizedArrayType)) {
            return false;
        }
        return arrayType.totalDepth == totalDepth && arrayType.componentType == componentType &&
            arrayType.size == _size;
    }
}

public immutable class StringLiteralType : SizedArrayType {
    private dstring _value;

    public this(dstring value) {
        super(AtomicType.UINT32, value.length);
        _value = value;
    }

    @property public dstring value() {
        return _value;
    }

    public override bool convertibleTo(inout Type type) {
        // Allow identity conversion
        if (opEquals(type)) {
            return true;
        }
        // Allow sized array conversions
        if (super.convertibleTo(type)) {
            return true;
        }
        // Can interpret as an unsigned integer literal type if the string contains only a single character
        if (_value.length != 1) {
            return false;
        }
        auto character = new immutable UnsignedIntegerLiteralType(_value[0]);
        return character.convertibleTo(type);
    }

    public override string toString() {
        return format("lit_string(%s)", _value);
    }

    mixin literalTypeOpEquals!StringLiteralType;
}
