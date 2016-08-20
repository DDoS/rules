module ruleslang.semantic.type;

import std.format : format;
import std.algorithm.comparison : min;
import std.algorithm.searching : canFind;
import std.exception : assumeUnique;
import std.math: isNaN, isInfinity;
import std.utf : codeLength;

import ruleslang.evaluation.value;
import ruleslang.util;

public enum ConversionKind {
    WIDENING = false,
    NARROWING = true
}

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
    STRING_LITERAL_TO_UTF16,
    REFERENCE_WIDENING
}

public ConversionKind getKind(TypeConversion conversion) {
    final switch (conversion) with (TypeConversion) {
        case IDENTITY:
        case INTEGER_WIDEN:
        case INTEGER_TO_FLOAT:
        case FLOAT_WIDEN:
        case SIZED_ARRAY_SHORTEN:
        case SIZED_ARRAY_TO_UNSIZED:
        case REFERENCE_WIDENING:
            return ConversionKind.WIDENING;
        case INTEGER_LITERAL_NARROW:
        case FLOAT_LITERAL_NARROW:
        case STRING_LITERAL_TO_UTF8:
        case STRING_LITERAL_TO_UTF16:
            return ConversionKind.NARROWING;
    }
    assert (0);
}

public class TypeConversionChain {
    private TypeConversion[] chain;

    public this(TypeConversion[] chain...) {
        this.chain = chain;
    }

    mixin generateBuilderMethods!(__traits(allMembers, TypeConversion));

    public override bool opEquals(Object other) {
        auto conversions = other.exactCastImmutable!TypeConversionChain();
        return conversions !is null && chain == conversions.chain;
    }

    public size_t length() {
        return chain.length;
    }

    public TypeConversionChain clone() {
        return new TypeConversionChain(chain.dup);
    }

    public TypeConversionChain copy(TypeConversionChain other) {
        chain = other.chain.dup;
        return this;
    }

    public TypeConversionChain reset() {
        chain.length = 0;
        return this;
    }

    public ConversionKind conversionKind() {
        foreach (conversion; chain) {
            if (conversion.getKind() is ConversionKind.NARROWING) {
                return ConversionKind.NARROWING;
            }
        }
        return ConversionKind.WIDENING;
    }

    public bool isIdentity() {
        return chain.length == 1 && chain[0] == TypeConversion.IDENTITY;
    }

    public bool isReferenceWidening() {
        if (chain.length <= 0 || isIdentity()) {
            return false;
        }
        foreach (conversion; chain) {
            switch (conversion) with (TypeConversion) {
                case IDENTITY:
                case REFERENCE_WIDENING:
                    continue;
                default:
                    return false;
            }
        }
        return true;
    }

    public bool isNumeric() {
        if (chain.length <= 0 || isIdentity()) {
            return false;
        }
        foreach (conversion; chain) {
            switch (conversion) with (TypeConversion) {
                case IDENTITY:
                case INTEGER_WIDEN:
                case INTEGER_TO_FLOAT:
                case FLOAT_WIDEN:
                case INTEGER_LITERAL_NARROW:
                case FLOAT_LITERAL_NARROW:
                    continue;
                default:
                    return false;
            }
        }
        return true;
    }

    public override string toString() {
        return format("Conversions(%s)", chain.join!(" -> ", "a.to!string"));
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

public bool typesEqual(immutable(Type)[] as, immutable(Type)[] bs) {
    if (as.length != bs.length) {
        return false;
    }
    foreach (i, a; as) {
        if (!a.opEquals(bs[i])) {
            return false;
        }
    }
    return true;
}

public immutable interface Type {
    public bool convertibleTo(immutable Type type, TypeConversionChain conversions);
    public immutable(Type) lowestUpperBound(immutable Type other);
    public string toString();
    public bool opEquals(immutable Type type);
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
        FP32, FP64
    ];
    private static immutable immutable(AtomicType)[][immutable(AtomicType)] SUPERTYPES;
    private static immutable immutable(AtomicType)[][immutable(AtomicType)] CONVERSIONS;
    private static immutable immutable(AtomicType)[immutable(AtomicType)] UNSIGNED_TO_SIGNED;
    private static immutable immutable(AtomicType)[immutable(AtomicType)] SIGNED_TO_UNSIGNED;
    private static immutable immutable(AtomicType)[immutable(AtomicType)] INTEGER_TO_FLOAT;
    private string name;
    private uint bitCount;
    private bool signed;
    private bool fp;

    public static this() {
        immutable(AtomicType)[][immutable(AtomicType)] supertypes = [
            BOOL: [],
            SINT8: [SINT16],
            UINT8: [UINT16, SINT16],
            SINT16: [SINT32],
            UINT16: [UINT32, SINT32],
            SINT32: [SINT64, FP32],
            UINT32: [UINT64, SINT64, FP32],
            SINT64: [FP64],
            UINT64: [FP64],
            FP32: [FP64],
            FP64: []
        ];
        auto supertypesCopy = supertypes.dup;
        SUPERTYPES = supertypesCopy.assumeUnique();

        auto conversions = supertypes.transitiveClosure();
        conversions.rehash;
        CONVERSIONS = conversions.assumeUnique();

        immutable(AtomicType)[immutable(AtomicType)] unsignedToSigned = [
           UINT8: SINT8, UINT16: SINT16, UINT32: SINT32, UINT64: SINT64,
        ];
        UNSIGNED_TO_SIGNED = unsignedToSigned.assumeUnique();

        immutable(AtomicType)[immutable(AtomicType)] signedToUnsigned = [
           SINT8: UINT8, SINT16: UINT16, SINT32: UINT32, SINT64: UINT64,
        ];
        SIGNED_TO_UNSIGNED = signedToUnsigned.assumeUnique();

        immutable(AtomicType)[immutable(AtomicType)] integerToFloat = [
           UINT8: FP32, SINT8: FP32, UINT16: FP32, SINT16: FP32,
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

    public bool inRange(T)(T value) if (__traits(isIntegral, T) || __traits(isFloating, T)) {
        if (isBoolean()) {
            // No non-boolean value is in range of a boolean
            return false;
        }
        if (fp) {
            // Check if the value fits in this float type range
            static if (__traits(isFloating, T)) {
                // If the value is a float, NaN and infinity are part of the valid range
                if (isNaN(value) || isInfinity(value)) {
                    return true;
                }
            }
            final switch (bitCount) {
                case 32:
                    return value >= -0x1.fffffeP+127f && value <= 0x1.fffffeP+127f;
                case 64:
                    return value >= -0x1.fffffffffffffP+1023 && value <= 0x1.fffffffffffffP+1023;
            }
        }
        // A float is never in range of an int type
        static if (__traits(isFloating, T)) {
            return false;
        } else static if (__traits(isUnsigned, T)) {
            // The value is an unsigned int
            if (!signed) {
                // The type is an unsigned int
                return checkUnsignedRange(value);
            }
            // The type is signed, only need to check the upper limit
            return value <= cast(ulong) (-1L >>> (65 - bitCount));
        } else {
            //  The value is a signed int
            if (!signed) {
                // The type is an unsigned int
                return checkUnsignedRange(value);
            }
            // The type is a signed int
            return value >= cast(long) (-1L << (bitCount - 1)) && value <= cast(long) (-1L >>> (65 - bitCount));
        }
    }

    private bool checkUnsignedRange(T)(T value) {
        return value >= 0 && cast(ulong) value <= (cast(ulong) -1 >>> (64 - bitCount));
    }

    public override bool convertibleTo(immutable Type type, TypeConversionChain conversions) {
        auto atomic = type.exactCastImmutable!AtomicType();
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

    public override immutable(Type) lowestUpperBound(immutable Type other) {
        // A LUB exists with another atomic type
        auto atomicOther = other.exactCastImmutable!AtomicType();
        if (atomicOther !is null) {
            return lowestUpperBound!AtomicType(atomicOther);
        }
        // A LUB exists with an atomic literal type
        auto literalOther = cast(immutable AtomicLiteralType) other;
        if (literalOther !is null) {
            return lowestUpperBound!AtomicLiteralType(literalOther);
        }
        // There are no LUB for any other type
        return null;
    }

    private immutable(Type) lowestUpperBound(T)(immutable T other) {
        // If any type is a supe type of the other, it is the LUB
        auto ignored = new TypeConversionChain();
        auto thisToOther = convertibleTo(other, ignored);
        auto otherToThis = other.convertibleTo(this, ignored);
        // This also includes the case where they are the same type
        if (thisToOther && otherToThis) {
            assert(opEquals(other));
            return this;
        }
        if (thisToOther && !otherToThis) {
            return other;
        }
        if (!thisToOther && otherToThis) {
            return this;
        }
        // Otherwise we get the super types of each
        auto thisParents = this.getSupertypes();
        static if (is(T : AtomicType)) {
            auto otherParents = other.getSupertypes();
        } else static if (is(T : AtomicLiteralType)) {
            // For a literal type, that is the equivalent atomic type
            auto otherParents = [other.getBackingType()];
        } else {
            static assert (0);
        }
        // Then we recurse on each combinatio of super types, and keep the smallest result
        immutable(Type)* candidate = null;
        foreach (thisParent; thisParents) {
            foreach (otherParent; otherParents) {
                auto lub = thisParent.lowestUpperBound(otherParent);
                if (lub is null) {
                    continue;
                }
                if (candidate == null || lub.convertibleTo(*candidate, ignored)) {
                    candidate = &lub;
                }
            }
        }
        // It's possible that no LUB exists
        return candidate == null ? null : *candidate;
    }

    public immutable(AtomicType)[] getSupertypes() {
        return SUPERTYPES[this];
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

    public override bool opEquals(immutable Type type) {
        auto atomicType = type.exactCastImmutable!AtomicType();
        return this is atomicType;
    }
}

private mixin template literalTypeOpEquals(L) {
    public override bool opEquals(immutable Type type) {
        auto literalType = type.exactCastImmutable!(L);
        return literalType !is null && _value == literalType._value;
    }
}

public immutable interface LiteralType : Type {
    public bool specializableTo(immutable Type type, TypeConversionChain conversions);
    public immutable(Type) getBackingType();
}

public immutable interface AtomicLiteralType : LiteralType {
    public immutable(Value) asValue();
    public immutable(AtomicType) getBackingType();
}

public immutable class BooleanLiteralType : AtomicLiteralType {
    private bool _value;

    public this(bool value) {
        _value = value;
    }

    @property public bool value() {
        return _value;
    }

    public override bool convertibleTo(immutable Type type, TypeConversionChain conversions) {
        if (opEquals(type)) {
            conversions.thenIdentity();
            return true;
        }
        // Can only cast to the atomic type bool
        auto atomic = type.exactCastImmutable!AtomicType();
        if (atomic !is null && atomic.opEquals(AtomicType.BOOL)) {
            conversions.thenIdentity();
            return true;
        }
        return false;
    }

    public override bool specializableTo(immutable Type type, TypeConversionChain conversions) {
        // No possible specializations for literal booleans
        return convertibleTo(type, conversions);
    }

    public override immutable(Type) lowestUpperBound(immutable Type other) {
        if (opEquals(other)) {
            return this;
        }
        // The only two boolean types are the atomic and literal. Their LUB is BOOL
        if (other.opEquals(AtomicType.BOOL) || other.exactCastImmutable!BooleanLiteralType() !is null) {
            return AtomicType.BOOL;
        }
        return null;
    }

    public override immutable(Value) asValue() {
        return valueOf(_value);
    }

    public override immutable(AtomicType) getBackingType() {
        return AtomicType.BOOL;
    }

    public override string toString() {
        return format("bool_lit(%s)", _value);
    }

    mixin literalTypeOpEquals!BooleanLiteralType;
}

public immutable interface IntegerLiteralType : AtomicLiteralType {
    public ulong unsignedValue();
    public long signedValue();
    public immutable(FloatLiteralType) toFloatLiteral();
}

public alias SignedIntegerLiteralType = IntegerLiteralTypeTemplate!long;
public alias UnsignedIntegerLiteralType = IntegerLiteralTypeTemplate!ulong;

private template IntegerLiteralTypeTemplate(T) {
    public immutable class IntegerLiteralTypeTemplate : IntegerLiteralType {
        private T _value;

        public this(T value) {
            _value = value;
        }

        @property public T value() {
            return _value;
        }

        public override bool convertibleTo(immutable Type type, TypeConversionChain conversions) {
            if (opEquals(type)) {
                conversions.thenIdentity();
                return true;
            }
            // Can cast the atomic type
            if (getBackingType().convertibleTo(type, conversions)) {
                return true;
            }
            // Can cast to a float literal type if converting the value to floating point gives the same value
            auto floatLiteral = type.exactCastImmutable!FloatLiteralType();
            if (floatLiteral !is null && floatLiteral.value == _value) {
                conversions.thenIntegerToFloat();
                return true;
            }
            // Can cast the atomic type
            return false;
        }

        public override bool specializableTo(immutable Type type, TypeConversionChain conversions) {
            if (convertibleTo(type, conversions)) {
                return true;
            }
            // Can convert to an atomic type if in range
            auto atomic = type.exactCastImmutable!AtomicType();
            if (atomic !is null && atomic.inRange(_value)) {
                if (atomic.isFloat()) {
                    conversions.thenIntegerLiteralNarrow();
                    conversions.thenIntegerToFloat();
                } else {
                    conversions.thenIntegerLiteralNarrow();
                }
                return true;
            }
            return false;
        }

        public override immutable(Type) lowestUpperBound(immutable Type other) {
            if (opEquals(other)) {
                return this;
            }
            auto ignored = new TypeConversionChain();
            if (convertibleTo(other, ignored)) {
                return other;
            }
            if (other.convertibleTo(this, ignored)) {
                return this;
            }
            return getBackingType().lowestUpperBound(other);
        }

        public override immutable(Value) asValue() {
            return valueOf(_value);
        }

        public override immutable(AtomicType) getBackingType() {
            static if (__traits(isUnsigned, T)) {
                return AtomicType.UINT64;
            } else {
                return AtomicType.SINT64;
            }
        }

        public override ulong unsignedValue() {
            return cast(ulong) _value;
        }

        public override long signedValue() {
            return cast(long) _value;
        }

        public override immutable(FloatLiteralType) toFloatLiteral() {
            return new immutable FloatLiteralType(_value);
        }

        public override string toString() {
            static if (__traits(isUnsigned, T)) {
                return format("uint_lit(%d)", _value);
            } else {
                return format("sint_lit(%d)", _value);
            }
        }

        mixin literalTypeOpEquals!(IntegerLiteralTypeTemplate!T);
    }
}

public immutable class FloatLiteralType : AtomicLiteralType {
    private double _value;

    public this(double value) {
        _value = value;
    }

    @property public double value() {
        return _value;
    }

    public override bool convertibleTo(immutable Type type, TypeConversionChain conversions) {
        if (opEquals(type)) {
            conversions.thenIdentity();
            return true;
        }
        // Can cast the atomic type
        return getBackingType().convertibleTo(type, conversions);
    }

    public override bool specializableTo(immutable Type type, TypeConversionChain conversions) {
        if (convertibleTo(type, conversions)) {
            return true;
        }
        // Can cast to an atomic type if in range
        auto atomic = type.exactCastImmutable!AtomicType();
        if (atomic !is null && atomic.inRange(_value)) {
            conversions.thenFloatLiteralNarrow();
            return true;
        }
        return false;
    }

    public override immutable(Type) lowestUpperBound(immutable Type other) {
        if (opEquals(other)) {
            return this;
        }
        auto ignored = new TypeConversionChain();
        if (convertibleTo(other, ignored)) {
            return other;
        }
        if (other.convertibleTo(this, ignored)) {
            return this;
        }
        return getBackingType().lowestUpperBound(other);
    }

    public override immutable(Value) asValue() {
        return valueOf(_value);
    }

    public override immutable(AtomicType) getBackingType() {
        return AtomicType.FP64;
    }

    public override string toString() {
        return format("fp_lit(%g)", _value);
    }

    mixin literalTypeOpEquals!FloatLiteralType;
}

public immutable interface CompositeType : Type {
    public bool hasMoreMembers(ulong count);
    public immutable(Type) getMemberType(ulong index);
}

public immutable class StringLiteralType : LiteralType, CompositeType {
    private dstring _value;
    private Type arrayType;
    private ulong utf8Length;
    private ulong utf16Length;

    public this(dstring value) {
        _value = value;
        arrayType = new immutable SizedArrayType(AtomicType.UINT32, value.length);
        utf8Length = value.codeLength!char;
        utf16Length = value.codeLength!wchar;
    }

    @property public dstring value() {
        return _value;
    }

    public immutable(Type) getArrayType() {
        return arrayType;
    }

    public override bool convertibleTo(immutable Type type, TypeConversionChain conversions) {
        // Allow identity conversion
        if (opEquals(type)) {
            conversions.thenIdentity();
            return true;
        }
        // Allow conversion to shorter string literals
        auto literalType = type.exactCastImmutable!StringLiteralType();
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
        return arrayType.convertibleTo(type, conversions);
    }

    public override bool specializableTo(immutable Type type, TypeConversionChain conversions) {
        if (convertibleTo(type, conversions)) {
            return true;
        }
        // Can convert the string to UTF-16 or UTF-8
        auto clone = conversions.clone().thenStringLiteralToUtf16();
        if (new immutable SizedArrayType(AtomicType.UINT16, utf16Length).convertibleTo(type, clone)) {
            conversions.copy(clone);
            return true;
        }
        clone = conversions.clone().thenStringLiteralToUtf8();
        if (new immutable SizedArrayType(AtomicType.UINT8, utf8Length).convertibleTo(type, clone)) {
            conversions.copy(clone);
            return true;
        }
        return false;
    }

    public override immutable(Type) lowestUpperBound(immutable Type other) {
        if (opEquals(other)) {
            return this;
        }
        auto ignored = new TypeConversionChain();
        if (convertibleTo(other, ignored)) {
            return other;
        }
        if (other.convertibleTo(this, ignored)) {
            return this;
        }
        // If the LUB fails, use the array form instead
        return arrayType.lowestUpperBound(other);
    }

    public override bool hasMoreMembers(ulong count) {
        return _value.length > count;
    }

    public override immutable(Type) getMemberType(ulong index) {
        return index >= _value.length ? null : new immutable UnsignedIntegerLiteralType(_value[index]);
    }

    public override immutable(Type) getBackingType() {
        return arrayType;
    }

    public override string toString() {
        return format("string_lit(\"%s\")", _value);
    }

    mixin literalTypeOpEquals!StringLiteralType;
}

public immutable class AnyType : CompositeType {
    public static immutable AnyType INSTANCE = new immutable AnyType();
    private this() {
    }

    public override bool convertibleTo(immutable Type type, TypeConversionChain conversions) {
        if (opEquals(type)) {
            conversions.thenIdentity();
            return true;
        }
        // Can cast any composite type or array type
        if (cast(immutable CompositeType) type !is null
                || cast(immutable ArrayType) type !is null) {
            conversions.thenReferenceWidening();
            return true;
        }
        return false;
    }

    public override immutable(Type) lowestUpperBound(immutable Type other) {
        // No other type can be greater than this, so just return this
        return this;
    }

    public override bool hasMoreMembers(ulong count) {
        return false;
    }

    public override immutable(Type) getMemberType(ulong index) {
        return null;
    }

    public override string toString() {
        return format("{}");
    }

    public override bool opEquals(immutable Type type) {
        return type.exactCastImmutable!(AnyType) !is null;
    }
}

public immutable class TupleType : CompositeType {
    private Type[] _memberTypes;

    public this(immutable(Type)[] memberTypes) {
        _memberTypes = memberTypes;
    }

    @property public immutable(Type)[] memberTypes() {
        return _memberTypes;
    }

    public override bool convertibleTo(immutable Type type, TypeConversionChain conversions) {
        // Allow identity conversion is allowed
        if (opEquals(type)) {
            conversions.thenIdentity();
            return true;
        }
        // Can convert to the any type
        if (type.opEquals(AnyType.INSTANCE)) {
            conversions.thenReferenceWidening();
            return true;
        }
        // Can convert to another composite type if its members are an ordered subset
        auto compositeType = cast(immutable CompositeType) type;
        if (compositeType is null) {
            return false;
        }
        if (compositeType.hasMoreMembers(_memberTypes.length)) {
            return false;
        }
        // Only allow identity conversion between members
        foreach (i, memberType; _memberTypes) {
            auto otherMemberType = compositeType.getMemberType(i);
            if (otherMemberType !is null && !memberType.opEquals(otherMemberType)) {
                return false;
            }
        }
        conversions.thenReferenceWidening();
        return true;
    }

    public override immutable(Type) lowestUpperBound(immutable Type other) {
        if (opEquals(other)) {
            return this;
        }
        auto ignored = new TypeConversionChain();
        if (convertibleTo(other, ignored)) {
            return other;
        }
        if (other.convertibleTo(this, ignored)) {
            return this;
        }
        // If the other type is a tuple, use the intersection of the ordered members as the LUB
        auto tupleType = cast(immutable TupleType) other;
        if (tupleType !is null) {
            immutable(Type)[] memberIntersection = [];
            foreach (i; 0 .. min(_memberTypes.length, tupleType.memberTypes.length)) {
                if (_memberTypes[i].opEquals(tupleType.memberTypes[i])) {
                    memberIntersection ~= _memberTypes[i];
                } else {
                    break;
                }
            }
            return new immutable TupleType(memberIntersection);
        }
        // If the other is an array type, the LUB is always the array type
        auto arrayType = cast(immutable ArrayType) other;
        if (arrayType !is null) {
            // If the array is sized, intersect by ordered members
            auto sizedArrayType = cast(immutable SizedArrayType) arrayType;
            if (sizedArrayType is null) {
                return other;
            }
            ulong arraySize = sizedArrayType.size;
            ulong tupleSize = 0;
            foreach (memberType; _memberTypes) {
                if (memberType.opEquals(sizedArrayType.componentType)) {
                    tupleSize += 1;
                } else {
                    break;
                }
            }
            auto size = min(tupleSize, arraySize);
            return new immutable TupleType(_memberTypes[0 .. size]);
        }
        return null;
    }

    public override bool hasMoreMembers(ulong count) {
        return  _memberTypes.length > count;
    }

    public override immutable(Type) getMemberType(ulong index) {
        return index >= _memberTypes.length ? null : _memberTypes[index];
    }

    public override string toString() {
        return format("{%s}", _memberTypes.join!", ");
    }

    public override bool opEquals(immutable Type type) {
        auto tupleType = type.exactCastImmutable!TupleType();
        return tupleType !is null && tupleType.memberTypes.typesEqual(_memberTypes);
    }
}

public immutable class StructureType : TupleType {
    private string[] _memberNames;

    public this(immutable(Type)[] memberTypes, immutable(string)[] memberNames) {
        assert(memberTypes.length > 0);
        assert(memberTypes.length == memberNames.length);
        super(memberTypes);
        _memberNames = memberNames;
    }

    private this() {
        super([]);
        _memberNames = [];
    }

    @property public immutable(string)[] memberNames() {
        return _memberNames;
    }

    public immutable(Type) getMemberType(string name) {
        foreach (i, memberName; _memberNames) {
            if (name == memberName) {
                return super.getMemberType(i);
            }
        }
        return null;
    }

    public override immutable(Type) getMemberType(ulong index) {
        return super.getMemberType(index);
    }

    public override bool convertibleTo(immutable Type type, TypeConversionChain conversions) {
        // Try the tuple conversions
        if (super.convertibleTo(type, conversions)) {
            return true;
        }
        // Otherwise try to convert to a structure type by member names
        auto structureType = type.exactCastImmutable!StructureType();
        if (structureType is null) {
            return false;
        }
        auto otherMemberNames = structureType.memberNames;
        if (otherMemberNames.length > memberNames.length) {
            return false;
        }
        // Each member of the other struct must be contained in this one
        foreach (i, otherName; otherMemberNames) {
            auto otherMemberType = structureType.getMemberType(i);
            auto memberType = getMemberType(otherName);
            if (!otherMemberType.opEquals(memberType)) {
                return false;
            }
        }
        conversions.thenReferenceWidening();
        return true;
    }

    public override immutable(Type) lowestUpperBound(immutable Type other) {
        // Try to convert to a structure type by member names
        auto structureType = other.exactCastImmutable!StructureType();
        if (structureType is null) {
            // Otherwise try the tuple LUB
            return super.lowestUpperBound(other);
        }
        // The LUB is the intersection of the member types, by name
        immutable(string)[] memberNameIntersection = [];
        immutable(Type)[] memberTypeIntersection = [];
        foreach (i, memberName; _memberNames) {
            auto otherMemberType = structureType.getMemberType(memberName);
            if (_memberTypes[i].opEquals(otherMemberType)) {
                memberNameIntersection ~= memberName;
                memberTypeIntersection ~= _memberTypes[i];
            }
        }
        return new immutable StructureType(memberTypeIntersection, memberNameIntersection);
    }

    public override string toString() {
        return format("{%s}", stringZip!" "(memberTypes, _memberNames).join!", "());
    }

    public override bool opEquals(immutable Type type) {
        auto structureType = type.exactCastImmutable!StructureType();
        return structureType !is null && structureType.memberNames == _memberNames
                && structureType.memberTypes.typesEqual(memberTypes);
    }
}

public immutable class ArrayType : CompositeType {
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

    public override bool convertibleTo(immutable Type type, TypeConversionChain conversions) {
        if (opEquals(type)) {
            conversions.thenIdentity();
            return true;
        }
        // Can convert to the any type
        if (type.opEquals(AnyType.INSTANCE)) {
            conversions.thenReferenceWidening();
            return true;
        }
        return false;
    }

    public override immutable(Type) lowestUpperBound(immutable Type other) {
        if (opEquals(other)) {
            return this;
        }
        auto ignored = new TypeConversionChain();
        if (convertibleTo(other, ignored)) {
            return other;
        }
        if (other.convertibleTo(this, ignored)) {
            return this;
        }
        // There is a lowest upper bound with a tuple type
        auto tupleType = cast(immutable TupleType) other;
        if (tupleType !is null) {
            // Defer to the tuple type
            return tupleType.lowestUpperBound(this);
        }
        // There is also with a string, but we need to convert to the array type first
        auto stringLiteralType = cast(immutable StringLiteralType) other;
        if (stringLiteralType !is null) {
            return lowestUpperBound(stringLiteralType.getArrayType());
        }
        return null;
    }

    public override bool hasMoreMembers(ulong count) {
        return false;
    }

    public override immutable(Type) getMemberType(ulong index) {
        return _componentType;
    }

    public override string toString() {
        return format("%s[]", _componentType.toString());
    }

    public override bool opEquals(immutable Type type) {
        auto arrayType = type.exactCastImmutable!ArrayType();
        return arrayType !is null && arrayType.totalDepth == _totalDepth
                && arrayType.componentType.opEquals(_componentType);
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

    public override bool convertibleTo(immutable Type type, TypeConversionChain conversions) {
        // Can convert to the any type
        if (type.opEquals(AnyType.INSTANCE)) {
            conversions.thenReferenceWidening();
            return true;
        }
        // Otherwise it must be an array type
        auto arrayType = cast(immutable ArrayType) type;
        if (arrayType is null) {
            return false;
        }
        // Can cast to unsized if the component and depth match
        if (arrayType.totalDepth != totalDepth || !arrayType.componentType.opEquals(componentType)) {
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

    public override bool hasMoreMembers(ulong count) {
        return _size > count;
    }

    public override string toString() {
        return format("%s[%d]", componentType.toString(), _size);
    }

    public override bool opEquals(immutable Type type) {
        auto arrayType = type.exactCastImmutable!SizedArrayType();
        return arrayType !is null && arrayType.totalDepth == totalDepth
                && arrayType.componentType.opEquals(componentType) && arrayType.size == _size;
    }
}
