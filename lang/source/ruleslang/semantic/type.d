module ruleslang.semantic.type;

import std.format : format;
import std.algorithm.searching : canFind;
import std.exception : assumeUnique;
import std.math: isNaN, isInfinity;
import std.utf : codeLength;

import ruleslang.util;

public enum TypeConversion {
    IDENTITY,
    INTEGER_WIDEN,
    INTEGER_TO_FLOAT,
    FLOAT_WIDEN,
    INTEGER_LITERAL_NARROW,
    FLOAT_LITERAL_NARROW,
    ARRAY_TO_COMPONENT,
    SIZED_ARRAY_SHORTEN,
    SIZED_ARRAY_TO_UNSIZED,
    STRING_LITERAL_TO_UTF8,
    STRING_LITERAL_TO_UTF16
}

public class TypeConversionChain {
    private TypeConversion[] chain;

    public this(TypeConversion[] chain...) {
        this.chain = chain;
    }

    mixin generateBuilderMethods!(__traits(allMembers, TypeConversion));

    public override bool opEquals(Object other) {
        auto conversions = cast(TypeConversionChain) other;
        if (conversions is null || typeid(conversions) != typeid(TypeConversionChain)) {
            return false;
        }
        return chain == conversions.chain;
    }

    public size_t length() {
        return chain.length;
    }

    public TypeConversionChain clone() {
        return new TypeConversionChain(chain.dup);
    }

    public override string toString() {
        return format("Conversions(%s)", chain.join!(" -> ", "to!string"));
    }

    private mixin template generateBuilderMethods(string conversion, conversions...) {
        mixin generateBuilderMethod!conversion;

        static if (conversions.length > 0) {
            mixin generateBuilderMethods!conversions;
        }
    }

    private mixin template generateBuilderMethod(string conversion) {
        mixin(
            `
            public TypeConversionChain then` ~ conversion.asciiSnakeToCamelCase(true) ~ `() {
                chain ~= TypeConversion.` ~ conversion ~ `;
                return this;
            }
            `
        );
    }
}

public immutable interface Type {
    public bool convertibleTo(inout Type type, ref TypeConversionChain conversions);
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

    public override bool convertibleTo(inout Type type, ref TypeConversionChain conversions) {
        auto atomic = cast(immutable AtomicType) type;
        if (atomic is null) {
            return false;
        }
        // Check if the conversion is valid
        if (!CONVERSIONS[this].canFind(atomic)) {
            return false;
        }
        // Find the conversion type
        if (this is atomic) {
            conversions.thenIdentity();
        } else if (isInteger()) {
            if (atomic.isInteger()) {
                conversions.thenIntegerWiden();
            } else if (atomic.isFloat()) {
                conversions.thenIntegerToFloat();
            } else {
                assert(0);
            }
        } else if (isFloat()) {
            if (atomic.isFloat()) {
                conversions.thenFloatWiden();
            } else {
                assert(0);
            }
        } else {
            assert(0);
        }
        return true;
    }

    public override string toString() {
        return name;
    }

    public override bool opEquals(inout Type type) {
        auto atomicType = cast(immutable AtomicType) type;
        if (atomicType is null || typeid(atomicType) != typeid(AtomicType)) {
            return false;
        }
        return this is atomicType;
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

    public override bool convertibleTo(inout Type type, ref TypeConversionChain conversions) {
        if (opEquals(type)) {
            conversions.thenIdentity();
            return true;
        }
        auto atomic = cast(immutable AtomicType) type;
        if (atomic is null) {
            return false;
        }
        if (atomic.inRange(_value)) {
            if (atomic.isFloat()) {
                conversions.thenIntegerToFloat();
                conversions.thenFloatLiteralNarrow();
            } else {
                conversions.thenIntegerLiteralNarrow();
            }
            return true;
        }
        return false;
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

    public override bool convertibleTo(inout Type type, ref TypeConversionChain conversions) {
        if (opEquals(type)) {
            conversions.thenIdentity();
            return true;
        }
        auto atomic = cast(immutable AtomicType) type;
        if (atomic is null) {
            return false;
        }
        if (atomic.inRange(_value)) {
            if (atomic.isFloat()) {
                conversions.thenIntegerToFloat();
                conversions.thenFloatLiteralNarrow();
            } else {
                conversions.thenIntegerLiteralNarrow();
            }
            return true;
        }
        return false;
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

    public override bool convertibleTo(inout Type type, ref TypeConversionChain conversions) {
        if (opEquals(type)) {
            conversions.thenIdentity();
            return true;
        }
        auto atomic = cast(immutable AtomicType) type;
        if (atomic is null) {
            return false;
        }
        if (atomic.inRange(_value)) {
            conversions.thenFloatLiteralNarrow();
            return true;
        }
        return false;
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

    public override bool convertibleTo(inout Type type, ref TypeConversionChain conversions) {
        // Only identity conversion is allowed
        if (opEquals(type)) {
            conversions.thenIdentity();
            return true;
        }
        return false;
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

    public override bool convertibleTo(inout Type type, ref TypeConversionChain conversions) {
        // If the sized array has size 1, we can interpret it as its component type
        if (_size == 1) {
            auto copy = conversions.clone().thenArrayToComponent();
            if (componentType.convertibleTo(type, copy)) {
                conversions = copy;
                return true;
            }
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
        if (sizedArrayType is null) {
            conversions.thenSizedArrayToUnsized();
            return true;
        }
        if (_size == sizedArrayType.size) {
            conversions.thenIdentity();
            return true;
        } else if (_size > sizedArrayType.size) {
            conversions.thenSizedArrayShorten();
            return true;
        }
        return false;
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
    private ulong utf8Length;
    private ulong utf16Length;

    public this(dstring value) {
        super(AtomicType.UINT32, value.length);
        _value = value;
        utf8Length = value.codeLength!char;
        utf16Length = value.codeLength!wchar;
    }

    @property public dstring value() {
        return _value;
    }

    public override bool convertibleTo(inout Type type, ref TypeConversionChain conversions) {
        // Allow identity conversion
        if (opEquals(type)) {
            conversions.thenIdentity();
            return true;
        }
        // Allow conversion to shorter string literals
        auto literalType = cast(immutable StringLiteralType) type;
        if (literalType !is null) {
            if (typeid(literalType) != typeid(StringLiteralType)) {
                return false;
            }
            auto literalLength = literalType.value.length;
            if (literalLength < _value.length && _value[0 .. literalLength] == literalType.value[0 .. literalLength]) {
                conversions.thenSizedArrayShorten();
                return true;
            }
            return false;
        }
        // Allow sized array conversions
        if (super.convertibleTo(type, conversions)) {
            return true;
        }
        // Can convert the string to UTF-16 or UTF-8
        auto copy = conversions.clone().thenStringLiteralToUtf16();
        if (new immutable SizedArrayType(AtomicType.UINT16, utf16Length).convertibleTo(type, copy)) {
            conversions = copy;
            return true;
        }
        copy = conversions.clone().thenStringLiteralToUtf8();
        if (new immutable SizedArrayType(AtomicType.UINT8, utf8Length).convertibleTo(type, copy)) {
            conversions = copy;
            return true;
        }
        return false;
    }

    public override string toString() {
        return format("lit_string(%s)", _value);
    }

    mixin literalTypeOpEquals!StringLiteralType;
}
