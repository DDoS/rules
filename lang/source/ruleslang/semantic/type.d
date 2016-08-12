module ruleslang.semantic.type;

import std.format : format;
import std.algorithm.searching : canFind;
import std.exception : assumeUnique;
import std.math: isNaN, isInfinity;
import std.utf : codeLength;
import std.bigint : BigInt;

import ruleslang.evaluation.value;
import ruleslang.util;

public enum TypeConversion {
    IDENTITY,
    INTEGER_WIDEN,
    INTEGER_TO_FLOAT,
    FLOAT_WIDEN,
    INTEGER_LITERAL_NARROW,
    FLOAT_LITERAL_NARROW,
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
        auto conversions = other.exactCastImmutable!(TypeConversionChain);
        return conversions !is null && chain == conversions.chain;
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
        mixin (
            `public TypeConversionChain then` ~ conversion.asciiSnakeToCamelCase(true) ~ `() {
                chain ~= TypeConversion.` ~ conversion ~ `;
                return this;
            }`
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
    public static immutable immutable(AtomicType)[] ALL_TYPES = BOOL ~ NUMERIC_TYPES;
    public static immutable immutable(AtomicType)[] NUMERIC_TYPES = INTEGER_TYPES ~ FLOATING_POINT_TYPES;
    public static immutable immutable(AtomicType)[] INTEGER_TYPES = SIGNED_INTEGER_TYPES ~ UNSIGNED_INTEGER_TYPES;
    public static immutable immutable(AtomicType)[] SIGNED_INTEGER_TYPES = [
        SINT8, SINT16, SINT32, SINT64
    ];
    public static immutable immutable(AtomicType)[] UNSIGNED_INTEGER_TYPES = [
        UINT8, UINT16, UINT32, UINT64
    ];
    public static immutable immutable(AtomicType)[] FLOATING_POINT_TYPES = [
        FP16, FP32, FP64
    ];
    private static immutable immutable(AtomicType)[][immutable(AtomicType)] CONVERSIONS;
    private static immutable immutable(AtomicType)[immutable(AtomicType)] UNSIGNED_TO_SIGNED;
    private static immutable immutable(AtomicType)[immutable(AtomicType)] SIGNED_TO_UNSIGNED;
    private static immutable immutable(AtomicType)[immutable(AtomicType)] INTEGER_TO_FLOAT;
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

        immutable(AtomicType)[immutable(AtomicType)] unsignedToSigned = [
           UINT8: SINT8, UINT16: SINT16, UINT32: SINT32, UINT64: SINT64,
        ];
        UNSIGNED_TO_SIGNED = unsignedToSigned.assumeUnique();

        immutable(AtomicType)[immutable(AtomicType)] signedToUnsigned = [
           SINT8: UINT8, SINT16: UINT16, SINT32: UINT32, SINT64: UINT64,
        ];
        SIGNED_TO_UNSIGNED = signedToUnsigned.assumeUnique();

        immutable(AtomicType)[immutable(AtomicType)] integerToFloat = [
           UINT8: FP16, SINT8: FP16, UINT16: FP16, SINT16: FP16,
           UINT32: FP32, SINT32: FP32, UINT64: FP32, SINT64: FP32,
        ];
        INTEGER_TO_FLOAT = integerToFloat.assumeUnique();
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

    public immutable(AtomicType) asSigned() {
        if (isSigned()) {
            return this;
        }
        return UNSIGNED_TO_SIGNED[this];
    }

    public bool hasSmallerRange(immutable AtomicType other) {
        if (this.bitCount == other.bitCount) {
            return !this.isSigned() && other.isSigned();
        }
        return this.bitCount < other.bitCount;
    }

    public override string toString() {
        return name;
    }

    public override bool opEquals(inout Type type) {
        auto atomicType = type.exactCastImmutable!(AtomicType);
        return this is atomicType;
    }
}

private mixin template literalTypeOpEquals(L) {
    public override bool opEquals(inout Type type) {
        auto literalType = type.exactCastImmutable!(L);
        return literalType !is null && _value == literalType._value;
    }
}

public immutable interface LiteralType : Type {
}

public immutable interface AtomicLiteralType : LiteralType {
    public immutable(Value) asValue();
    public immutable(AtomicType) getAtomicType();
}

public immutable class BooleanLiteralType : AtomicLiteralType {
    private bool _value;

    public this(bool value) {
        _value = value;
    }

    @property public bool value() {
        return _value;
    }

    public override bool convertibleTo(inout Type type, ref TypeConversionChain conversions) {
        if (opEquals(type)) {
            conversions.thenIdentity();
            return true;
        }
        // Can only cast to the atomic type bool
        auto atomic = cast(immutable AtomicType) type;
        if (atomic !is null && atomic == AtomicType.BOOL) {
            conversions.thenIdentity();
            return true;
        }
        return false;
    }

    public override immutable(Value) asValue() {
        return valueOf(_value);
    }

    public override immutable(AtomicType) getAtomicType() {
        return AtomicType.BOOL;
    }

    public override string toString() {
        return format("bool_lit(%s)", _value);
    }

    mixin literalTypeOpEquals!BooleanLiteralType;
}

public immutable class IntegerLiteralType : AtomicLiteralType {
    private BigInt _value;

    public this(long value) {
        _value = BigInt(value);
    }

    public this(ulong value) {
        _value = BigInt(value);
    }

    @property public BigInt value() {
        return _value;
    }

    public override bool convertibleTo(inout Type type, ref TypeConversionChain conversions) {
        if (opEquals(type)) {
            conversions.thenIdentity();
            return true;
        }
        // Can cast to a float literal type if converting the value to floating point gives the same value
        auto floatLiteral = type.exactCastImmutable!(FloatLiteralType);
        if (floatLiteral !is null
                && (_value < 0 ? floatLiteral.value == cast(long) _value : floatLiteral.value == cast(ulong) _value)) {
            conversions.thenIntegerToFloat();
            return true;
        }
        // Can cast to an atomic type if in range
        auto atomic = cast(immutable AtomicType) type;
        if (atomic is null) {
            return false;
        }
        bool inRange = _value < 0 ? atomic.inRange(cast(long) _value) : atomic.inRange(cast(ulong) _value);
        if (inRange) {
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

    public override immutable(Value) asValue() {
        return _value < 0 ? valueOf(cast(long) _value) : valueOf(cast(ulong) _value);
    }

    public override immutable(AtomicType) getAtomicType() {
        return _value < 0 ? AtomicType.SINT64 : AtomicType.UINT64;
    }

    public immutable(FloatLiteralType) toFloatLiteral() {
        return _value < 0 ? new immutable FloatLiteralType(cast(long) _value)
                : new immutable FloatLiteralType(cast(ulong) _value);
    }

    public override string toString() {
        return format("int_lit(%d)", _value);
    }

    mixin literalTypeOpEquals!IntegerLiteralType;
}

public immutable class FloatLiteralType : AtomicLiteralType {
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
        // Can cast to an atomic type if in range
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

    public override immutable(Value) asValue() {
        return valueOf(_value);
    }

    public override immutable(AtomicType) getAtomicType() {
        return AtomicType.FP64;
    }

    public override string toString() {
        return format("fp_lit(%g)", _value);
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
        auto arrayType = type.exactCastImmutable!(ArrayType);
        return arrayType !is null && arrayType.totalDepth == _totalDepth && arrayType.componentType == _componentType;
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
        auto arrayType = type.exactCastImmutable!(SizedArrayType);
        return arrayType !is null && arrayType.totalDepth == totalDepth
                && arrayType.componentType == componentType && arrayType.size == _size;
    }
}

public immutable class StringLiteralType : SizedArrayType, LiteralType {
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
        return format("string_lit(%s)", _value);
    }

    mixin literalTypeOpEquals!StringLiteralType;
}

public immutable class StructureType : Type {
    public immutable(Type) getMemberType(string name) {
        return null;
    }

    public override bool convertibleTo(inout Type type, ref TypeConversionChain conversions) {
        if (opEquals(type)) {
            conversions.thenIdentity();
            return true;
        }
        return false;
    }

    public override string toString() {
        return format("{}");
    }

    public override bool opEquals(inout Type type) {
        auto structureType = type.exactCastImmutable!(StructureType);
        return this is structureType;
    }
}
