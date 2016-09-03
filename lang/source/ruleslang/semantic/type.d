module ruleslang.semantic.type;

import std.format : format;
import std.array : split;
import std.algorithm.comparison : min;
import std.algorithm.searching : canFind;
import std.exception : assumeUnique;
import std.math: isNaN, isInfinity;
import std.utf : codeLength;

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
    STRING_LITERAL_TO_UTF8,
    STRING_LITERAL_TO_UTF16,
    REFERENCE_WIDENING,
    REFERENCE_NARROWING
}

public ConversionKind getKind(TypeConversion conversion) {
    final switch (conversion) with (TypeConversion) {
        case IDENTITY:
        case INTEGER_WIDEN:
        case INTEGER_TO_FLOAT:
        case FLOAT_WIDEN:
        case REFERENCE_WIDENING:
            return ConversionKind.WIDENING;
        case INTEGER_LITERAL_NARROW:
        case FLOAT_LITERAL_NARROW:
        case STRING_LITERAL_TO_UTF8:
        case STRING_LITERAL_TO_UTF16:
        case REFERENCE_NARROWING:
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

    public alias isNumericWidening = checkConversions!"INTEGER_WIDEN INTEGER_TO_FLOAT FLOAT_WIDEN";
    public alias isNumericNarrowing = checkConversions!"INTEGER_LITERAL_NARROW FLOAT_LITERAL_NARROW";
    public alias isReferenceWidening = checkConversions!"REFERENCE_WIDENING";
    public alias isReferenceNarrowing = checkConversions!"REFERENCE_NARROWING";

    private bool checkConversions(string cases)() {
        if (chain.length <= 0 || isIdentity()) {
            return false;
        }
        foreach (conversion; chain) {
            switch (conversion) with (TypeConversion) {
                case IDENTITY:
                mixin ("case " ~ cases.split().join!":\ncase "() ~ ":\n");
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
    private immutable struct DataInfo {
        private uint bitCount;
        private bool signed;
        private bool fp;
    }
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
    private static immutable immutable(AtomicType)[][immutable(DataInfo)] SUPERTYPES;
    private static immutable immutable(AtomicType)[][immutable(DataInfo)] CONVERSIONS;
    private static immutable immutable(AtomicType)[immutable(DataInfo)] UNSIGNED_TO_SIGNED;
    private static immutable immutable(AtomicType)[immutable(DataInfo)] SIGNED_TO_UNSIGNED;
    private static immutable immutable(AtomicType)[immutable(DataInfo)] INTEGER_TO_FLOAT;
    private static immutable immutable(AtomicType)[immutable(DataInfo)] INFO_TO_SINGLETON;
    public string name;
    private DataInfo info;

    public static this() {
        immutable(DataInfo) getInfo(immutable AtomicType type) {
            return type.info;
        }

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
        auto supertypesCopy = supertypes.dup.mapKeys!getInfo();
        SUPERTYPES = supertypesCopy.assumeUnique();

        auto conversions = supertypes.transitiveClosure().mapKeys!getInfo();
        conversions.rehash;
        CONVERSIONS = conversions.assumeUnique();

        immutable(AtomicType)[immutable(DataInfo)] unsignedToSigned = [
           UINT8.info: SINT8, UINT16.info: SINT16, UINT32.info: SINT32, UINT64.info: SINT64,
        ];
        UNSIGNED_TO_SIGNED = unsignedToSigned.assumeUnique();

        immutable(AtomicType)[immutable(DataInfo)] signedToUnsigned = [
           SINT8.info: UINT8, SINT16.info: UINT16, SINT32.info: UINT32, SINT64.info: UINT64,
        ];
        SIGNED_TO_UNSIGNED = signedToUnsigned.assumeUnique();

        immutable(AtomicType)[immutable(DataInfo)] integerToFloat = [
           UINT8.info: FP32, SINT8.info: FP32, UINT16.info: FP32, SINT16.info: FP32,
           UINT32.info: FP32, SINT32.info: FP32, UINT64.info: FP64, SINT64.info: FP64,
        ];
        INTEGER_TO_FLOAT = integerToFloat.assumeUnique();

        immutable(AtomicType)[immutable(DataInfo)] infoToSingleton = [
            BOOL.info: BOOL,
            UINT8.info: UINT8, SINT8.info: SINT8, UINT16.info: UINT16, SINT16.info: SINT16,
            UINT32.info: UINT32, SINT32.info: SINT32, UINT64.info: UINT64, SINT64.info: SINT64,
            FP32.info: FP32, FP64.info: FP64
        ];
        INFO_TO_SINGLETON = infoToSingleton.assumeUnique();
    }

    private this(string name, uint bitCount, bool signed, bool fp) {
        this.name = name;
        info = immutable DataInfo(bitCount, signed, fp);
    }

    @property public uint bitCount() {
        return info.bitCount;
    }

    public bool isBoolean() {
        return info.bitCount == 1;
    }

    public bool isInteger() {
        return info.bitCount > 1 && !info.fp;
    }

    public bool isSigned() {
        return info.signed;
    }

    public bool isFloat() {
        return info.fp;
    }

    public bool inRange(T)(T value) if (__traits(isIntegral, T) || __traits(isFloating, T)) {
        if (isBoolean()) {
            // No non-boolean value is in range of a boolean
            return false;
        }
        if (info.fp) {
            // Check if the value fits in this float type range
            static if (__traits(isFloating, T)) {
                // If the value is a float, NaN and infinity are part of the valid range
                if (isNaN(value) || isInfinity(value)) {
                    return true;
                }
            }
            final switch (info.bitCount) {
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
            if (!info.signed) {
                // The type is an unsigned int
                return checkUnsignedRange(value);
            }
            // The type is signed, only need to check the upper limit
            return value <= cast(ulong) (-1L >>> (65 - info.bitCount));
        } else {
            //  The value is a signed int
            if (!info.signed) {
                // The type is an unsigned int
                return checkUnsignedRange(value);
            }
            // The type is a signed int
            return value >= cast(long) (-1L << (info.bitCount - 1)) && value <= cast(long) (-1L >>> (65 - info.bitCount));
        }
    }

    private bool checkUnsignedRange(T)(T value) {
        return value >= 0 && cast(ulong) value <= (cast(ulong) -1 >>> (64 - info.bitCount));
    }

    public override bool convertibleTo(immutable Type type, TypeConversionChain conversions) {
        auto atomic = type.exactCastImmutable!AtomicType();
        if (atomic is null) {
            return false;
        }
        // Check if the conversion is valid
        if (!CONVERSIONS[info].canFind!((a, b) => a.info == b.info)(atomic)) {
            return false;
        }
        // Find the conversion type
        if (info == atomic.info) {
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

    public override immutable(Type) lowestUpperBound(immutable Type type) {
        // A LUB only exists with another atomic type
        auto other = cast(immutable AtomicType) type;
        if (other is null) {
            return null;
        }
        // If any type is a super type of the other, it is the LUB
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
        auto otherParents = other.getSupertypes();
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
        return SUPERTYPES[info];
    }

    public immutable(AtomicType) asSigned() {
        if (isSigned()) {
            return this;
        }
        return UNSIGNED_TO_SIGNED[info];
    }

    public override string toString() {
        return name;
    }

    public override bool opEquals(immutable Type type) {
        auto atomicType = cast(immutable AtomicType) type;
        return atomicType !is null && info == atomicType.info;
    }
}

public immutable interface LiteralType : Type {
    public bool specializableTo(immutable Type type, TypeConversionChain conversions);
}

public immutable interface AtomicLiteralType : LiteralType {
    public immutable(AtomicType) withoutLiteral();
}

public immutable class BooleanLiteralType : AtomicType, AtomicLiteralType {
    public bool value;

    public this(bool value) {
        super("bool_lit", 1, false, false);
        this.value = value;
    }

    public override bool convertibleTo(immutable Type type, TypeConversionChain conversions) {
        // Allow identity conversions
        if (opEquals(type)) {
            conversions.thenIdentity();
            return true;
        }
        // Otherwise try the super type conversions
        return AtomicType.BOOL.convertibleTo(type, conversions);
    }

    public override bool specializableTo(immutable Type type, TypeConversionChain conversions) {
        // No possible specializations for literal booleans
        return convertibleTo(type, conversions);
    }

    public override immutable(Type) lowestUpperBound(immutable Type other) {
        // There is a lowest upper bound with another boolean literal type
        auto booleanLiteral = cast (immutable BooleanLiteralType) other;
        if (booleanLiteral is null) {
            // Otherwise try the Atomic LUB
            return super.lowestUpperBound(other);
        }
        // If the values are equal, return this, else return bool
        if (value == booleanLiteral.value) {
            return this;
        }
        return AtomicType.BOOL;
    }

    public override immutable(AtomicType) withoutLiteral() {
        return AtomicType.BOOL;
    }

    public override string toString() {
        return format("bool_lit(%s)", value);
    }

    public override bool opEquals(immutable Type type) {
        auto literalType = type.exactCastImmutable!BooleanLiteralType();
        return literalType !is null && value == literalType.value;
    }
}

public immutable interface IntegerLiteralType : AtomicLiteralType {
    public ulong unsignedValue();
    public long signedValue();
    public immutable(FloatLiteralType) toFloatLiteral();
}

public alias SignedIntegerLiteralType = IntegerLiteralTypeTemplate!long;
public alias UnsignedIntegerLiteralType = IntegerLiteralTypeTemplate!ulong;

private template IntegerLiteralTypeTemplate(T) {
    public immutable class IntegerLiteralTypeTemplate : AtomicType, IntegerLiteralType {
        public T value;

        public this(T value) {
            static if (__traits(isUnsigned, T)) {
                this(AtomicType.UINT64, value);
            } else {
                this(AtomicType.SINT64, value);
            }
        }

        public this(immutable AtomicType backing, T value) {
            assert (!backing.isFloat());
            static if (__traits(isUnsigned, T)) {
                assert (!backing.isSigned());
                super("uint_lit", backing.bitCount, backing.isSigned(), backing.isFloat());
            } else {
                assert (backing.isSigned());
                super("sint_lit", backing.bitCount, backing.isSigned(), backing.isFloat());
            }
            this.value = value;
            assert (inRange(value));
        }

        public override bool convertibleTo(immutable Type type, TypeConversionChain conversions) {
            if (opEquals(type)) {
                conversions.thenIdentity();
                return true;
            }
            // Can cast to an integer literal if the values are the same
            auto integerLiteral = type.exactCastImmutable!(IntegerLiteralTypeTemplate!T);
            if (integerLiteral !is null && withoutLiteral().convertibleTo(integerLiteral.withoutLiteral(), conversions)
                    && value == integerLiteral.value) {
                return true;
            }
            // Can cast to a float literal type if converting the value to floating point gives the same value
            auto floatLiteral = type.exactCastImmutable!FloatLiteralType();
            if (floatLiteral !is null && withoutLiteral().convertibleTo(floatLiteral.withoutLiteral(), conversions)
                    && value == floatLiteral.value) {
                return true;
            }
            // Try the super type conversions
            return super.convertibleTo(type, conversions);
        }

        public override bool specializableTo(immutable Type type, TypeConversionChain conversions) {
            if (convertibleTo(type, conversions)) {
                return true;
            }
            // Can convert to an atomic type if in range
            auto atomic = cast(immutable AtomicType) type;
            if (atomic !is null && atomic.inRange(value)) {
                // If the other is a literal, the values must be equal
                auto signedIntegerLiteral = cast(immutable SignedIntegerLiteralType) type;
                if (signedIntegerLiteral !is null && signedValue() != signedIntegerLiteral.value) {
                    return false;
                }
                auto unsignedIntegerLiteral = cast(immutable UnsignedIntegerLiteralType) type;
                if (unsignedIntegerLiteral !is null && unsignedValue() != unsignedIntegerLiteral.value) {
                    return false;
                }
                auto floatLiteral = cast(immutable FloatLiteralType) type;
                if (floatLiteral !is null && value != floatLiteral.value) {
                    return false;
                }
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
            // If we have another atomic literal, try without literals
            auto atomicLiteral = cast(immutable AtomicLiteralType) other;
            if (atomicLiteral !is null) {
                return withoutLiteral().lowestUpperBound(atomicLiteral.withoutLiteral());
            }
            // Try the atomic LUB
            return withoutLiteral().lowestUpperBound(other);
        }

        public override ulong unsignedValue() {
            return cast(ulong) value;
        }

        public override long signedValue() {
            return cast(long) value;
        }

        public override immutable(FloatLiteralType) toFloatLiteral() {
            return new immutable FloatLiteralType(value);
        }

        public override immutable(AtomicType) withoutLiteral() {
            return INFO_TO_SINGLETON[info];
        }

        public override string toString() {
            static if (__traits(isUnsigned, T)) {
                return format("uint_lit(%d)", value);
            } else {
                return format("sint_lit(%d)", value);
            }
        }

        public override bool opEquals(immutable Type type) {
            auto literalType = type.exactCastImmutable!(IntegerLiteralTypeTemplate!T)();
            return literalType !is null && info == literalType.info && value == literalType.value;
        }
    }
}

public immutable class FloatLiteralType : AtomicType, AtomicLiteralType {
    public double value;

    public this(double value) {
        this(AtomicType.FP64, value);
    }

    public this(immutable AtomicType backing, double value) {
        assert (backing.isFloat());
        super("fp_lit", backing.bitCount, backing.isSigned(), backing.isFloat());
        this.value = value;
        assert (inRange(value));
    }

    public override bool convertibleTo(immutable Type type, TypeConversionChain conversions) {
        if (opEquals(type)) {
            conversions.thenIdentity();
            return true;
        }
        // Can cast to a float literal type the values are the same
        auto floatLiteral = type.exactCastImmutable!FloatLiteralType();
        if (floatLiteral !is null && withoutLiteral().convertibleTo(floatLiteral.withoutLiteral(), conversions)
                && value == floatLiteral.value) {
            return true;
        }
        // Try the super type conversions
        return super.convertibleTo(type, conversions);
    }

    public override bool specializableTo(immutable Type type, TypeConversionChain conversions) {
        if (convertibleTo(type, conversions)) {
            return true;
        }
        // Can cast to an atomic type if in range
        auto atomic = type.exactCastImmutable!AtomicType();
        if (atomic !is null && atomic.inRange(value)) {
            // If the other is a literal, the values must be equal
            auto floatLiteral = cast(immutable FloatLiteralType) type;
            if (floatLiteral !is null && value != floatLiteral.value) {
                return false;
            }
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
        // If we have another atomic literal, try without literals
        auto atomicLiteral = cast(immutable AtomicLiteralType) other;
        if (atomicLiteral !is null) {
            return withoutLiteral().lowestUpperBound(atomicLiteral.withoutLiteral());
        }
        // Try the atomic LUB
        return withoutLiteral().lowestUpperBound(other);
    }

    public override immutable(AtomicType) withoutLiteral() {
        return INFO_TO_SINGLETON[info];
    }

    public override string toString() {
        return format("fp_lit(%g)", value);
    }

    public override bool opEquals(immutable Type type) {
        auto literalType = type.exactCastImmutable!FloatLiteralType();
        return literalType !is null && info == literalType.info && value == literalType.value;
    }
}

public immutable interface ReferenceType : Type {
    public immutable(Type) getMemberType(ulong index);
}

public immutable interface CompositeType : ReferenceType {
    public ulong getMemberCount();
}

public immutable class AnyType : CompositeType {
    public static immutable AnyType INSTANCE = new immutable AnyType();
    public static immutable TypeIdentity INFO = INSTANCE.identity();

    private this() {
    }

    public override bool convertibleTo(immutable Type type, TypeConversionChain conversions) {
        // Can only perform an identity conversion
        if (opEquals(type)) {
            conversions.thenIdentity();
            return true;
        }
        return false;
    }

    public override immutable(Type) lowestUpperBound(immutable Type other) {
        auto referenceType = cast(immutable ReferenceType) other;
        if (referenceType !is null) {
            // No other reference type can be greater than this, so just return this
            return this;
        }
        return null;
    }

    public override ulong getMemberCount() {
        return 0;
    }

    public override immutable(Type) getMemberType(ulong index) {
        return null;
    }

    public override string toString() {
        return format("{}");
    }

    public override bool opEquals(immutable Type type) {
        return cast(immutable AnyType) type !is null;
    }
}

public immutable class TupleType : CompositeType {
    public Type[] memberTypes;

    public this(immutable(Type)[] memberTypes) {
        assert(memberTypes.length > 0);
        this.memberTypes = memberTypes;
    }

    public override bool convertibleTo(immutable Type type, TypeConversionChain conversions) {
        // Allow identity conversion
        if (opEquals(type)) {
            conversions.thenIdentity();
            return true;
        }
        // Can convert to the any type
        if (type.opEquals(AnyType.INSTANCE)) {
            conversions.thenReferenceWidening();
            return true;
        }
        // Can convert to another tuple type if its members are an ordered subset
        auto tupleType = type.exactCastImmutable!TupleType();
        if (tupleType is null) {
            return false;
        }
        if (tupleType.getMemberCount() > memberTypes.length) {
            return false;
        }
        // Only allow identity conversion between members
        foreach (i, memberType; memberTypes) {
            auto otherMemberType = tupleType.getMemberType(i);
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
            foreach (i; 0 .. min(memberTypes.length, tupleType.memberTypes.length)) {
                if (memberTypes[i].opEquals(tupleType.memberTypes[i])) {
                    memberIntersection ~= memberTypes[i];
                } else {
                    break;
                }
            }
            if (memberIntersection.length <= 0) {
                return AnyType.INSTANCE;
            }
            return new immutable TupleType(memberIntersection);
        }
        // Otherwise if the other is a reference type, return the any type
        if (cast(ReferenceType) other !is null) {
            return AnyType.INSTANCE;
        }
        return null;
    }

    public override ulong getMemberCount() {
        return memberTypes.length;
    }

    public override immutable(Type) getMemberType(ulong index) {
        return index >= memberTypes.length ? null : memberTypes[index];
    }

    public override string toString() {
        return format("{%s}", memberTypes.join!", ");
    }

    public override bool opEquals(immutable Type type) {
        auto tupleType = type.exactCastImmutable!TupleType();
        return tupleType !is null && tupleType.memberTypes.typesEqual(memberTypes);
    }
}

public immutable class StructureType : TupleType {
    public string[] memberNames;

    public this(immutable(Type)[] memberTypes, immutable(string)[] memberNames) {
        super(memberTypes);
        assert(memberTypes.length == memberNames.length);
        this.memberNames = memberNames;
    }

    public immutable(Type) getMemberType(string name) {
        foreach (i, memberName; memberNames) {
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
        // Allow identity conversion
        if (opEquals(type)) {
            conversions.thenIdentity();
            return true;
        }
        // Try to convert to a structure type by member names
        auto structureType = cast(immutable StructureType) type;
        if (structureType is null) {
            // Otherwise try the tuple conversions
            return super.convertibleTo(type, conversions);
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
        auto structureType = cast (immutable StructureType) other;
        if (structureType is null) {
            // Otherwise try the tuple LUB
            return super.lowestUpperBound(other);
        }
        // The LUB is the intersection of the member types, by name
        immutable(string)[] memberNameIntersection = [];
        immutable(Type)[] memberTypeIntersection = [];
        foreach (i, memberName; memberNames) {
            auto otherMemberType = structureType.getMemberType(memberName);
            if (memberTypes[i].opEquals(otherMemberType)) {
                memberNameIntersection ~= memberName;
                memberTypeIntersection ~= memberTypes[i];
            }
        }
        if (memberTypeIntersection.length <= 0) {
            return AnyType.INSTANCE;
        }
        return new immutable StructureType(memberTypeIntersection, memberNameIntersection);
    }

    public override string toString() {
        return format("{%s}", stringZip!" "(memberTypes, memberNames).join!", "());
    }

    public override bool opEquals(immutable Type type) {
        auto structureType = type.exactCastImmutable!StructureType();
        return structureType !is null && structureType.memberNames == memberNames
                && structureType.memberTypes.typesEqual(memberTypes);
    }
}

public immutable class ArrayType : ReferenceType {
    public Type componentType;
    public uint totalDepth;

    public this(immutable Type componentType) {
        this.componentType = componentType;
        // Include depth of component type
        auto depth = 1;
        auto arrayComponentType = cast(immutable ArrayType) componentType;
        if (arrayComponentType !is null) {
            depth += arrayComponentType.totalDepth;
        }
        totalDepth = depth;
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
        // When it comes to arrays, only polymorphism on size it allowed, which means
        // the types are linearly ordered and do not form a tree. So the above checks
        // should be sufficient.
        // If the other is a reference type, return the any type
        if (cast(ReferenceType) other !is null) {
            return AnyType.INSTANCE;
        }
        return null;
    }

    public override immutable(Type) getMemberType(ulong index) {
        return componentType;
    }

    public override string toString() {
        return format("%s[]", componentType.toString());
    }

    public override bool opEquals(immutable Type type) {
        auto arrayType = type.exactCastImmutable!ArrayType();
        return arrayType !is null && arrayType.totalDepth == totalDepth
                && arrayType.componentType.opEquals(componentType);
    }
}

public immutable class SizedArrayType : ArrayType, CompositeType {
    public ulong size;

    public this(immutable Type componentType, ulong size) {
        super(componentType);
        this.size = size;
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
            conversions.thenReferenceWidening();
            return true;
        }
        if (size == sizedArrayType.size) {
            conversions.thenIdentity();
            return true;
        } else if (size > sizedArrayType.size) {
            conversions.thenReferenceWidening();
            return true;
        }
        return false;
    }

    public override ulong getMemberCount() {
        return size;
    }

    public override immutable(Type) getMemberType(ulong index) {
        return index >= size ? null : componentType;
    }

    public override string toString() {
        return format("%s[%d]", componentType.toString(), size);
    }

    public override bool opEquals(immutable Type type) {
        auto arrayType = type.exactCastImmutable!SizedArrayType();
        return arrayType !is null && arrayType.totalDepth == totalDepth
                && arrayType.componentType.opEquals(componentType) && arrayType.size == size;
    }
}

public immutable class AnyTypeLiteral : AnyType, LiteralType {
    public static immutable AnyTypeLiteral INSTANCE = new immutable AnyTypeLiteral();

    public override bool specializableTo(immutable Type type, TypeConversionChain conversions) {
        if (super.convertibleTo(type, conversions)) {
            return true;
        }
        // Can specialize to any another reference type
        if (cast(immutable ReferenceType) type !is null) {
            conversions.thenReferenceNarrowing();
            return true;
        }
        return false;
    }

    public override bool opEquals(immutable Type type) {
        return cast(immutable AnyType) type !is null;
    }
}

public immutable class TupleLiteralType : TupleType, LiteralType {
    public this(immutable(Type)[] memberTypes) {
        super(memberTypes);
    }

    public override bool specializableTo(immutable Type type, TypeConversionChain conversions) {
        if (convertibleTo(type, conversions)) {
            return true;
        }
        // Can specialize to another reference type
        auto referenceType = cast(immutable ReferenceType) type;
        if (referenceType is null) {
            return false;
        }
        // The members must be convertible to or specializable to that of the other
        foreach (i, memberType; memberTypes) {
            auto otherMemberType = referenceType.getMemberType(i);
            if (otherMemberType is null) {
                continue;
            }
            auto literalMemberType = cast(immutable LiteralType) memberType;
            bool convertible;
            auto ignored = new TypeConversionChain();
            if (literalMemberType !is null) {
                convertible = literalMemberType.specializableTo(otherMemberType, ignored);
            } else {
                convertible = memberType.convertibleTo(otherMemberType, ignored);
            }
            if (!convertible) {
                return false;
            }
        }
        conversions.thenReferenceNarrowing();
        return true;
    }

    public override bool opEquals(immutable Type type) {
        auto tupleType = type.exactCastImmutable!TupleLiteralType();
        return tupleType !is null && tupleType.memberTypes.typesEqual(memberTypes);
    }
}

public immutable class StructureLiteralType : StructureType, LiteralType {
    public this(immutable(Type)[] memberTypes, immutable(string)[] memberNames) {
        super(memberTypes, memberNames);
    }

    public override bool specializableTo(immutable Type type, TypeConversionChain conversions) {
        if (convertibleTo(type, conversions)) {
            return true;
        }
        // Only allow specialization to structure types
        auto structureType = cast(immutable StructureType) type;
        if (structureType is null) {
            return false;
        }
        // Each member must be specializable to that of the other struct
        foreach (i, otherName; structureType.memberNames) {
            auto otherMemberType = structureType.getMemberType(i);
            auto memberType = getMemberType(otherName);
            if (memberType is null) {
                continue;
            }
            auto literalMemberType = cast(immutable LiteralType) memberType;
            bool convertible;
            auto ignored = new TypeConversionChain();
            if (literalMemberType !is null) {
                convertible = literalMemberType.specializableTo(otherMemberType, ignored);
            } else {
                convertible = memberType.convertibleTo(otherMemberType, ignored);
            }
            if (!convertible) {
                return false;
            }
        }
        conversions.thenReferenceNarrowing();
        return true;
    }

    public override bool opEquals(immutable Type type) {
        auto structureType = type.exactCastImmutable!StructureLiteralType();
        return structureType !is null && structureType.memberNames == memberNames
                && structureType.memberTypes.typesEqual(memberTypes);
    }
}

public immutable class SizedArrayLiteralType : SizedArrayType, LiteralType {
    private Type[] _memberTypes;

    public this(immutable(Type)[] memberTypes, ulong size) {
        assert (memberTypes.length > 0);
        assert (size > 0 && memberTypes.length <= size + 1);
        _memberTypes = memberTypes;
        // The component type is the lowest upper bound of the components
        auto firstType = memberTypes[0];
        immutable(Type)* componentType = &firstType;
        foreach (memberType; memberTypes[1 .. $]) {
            auto lub = (*componentType).lowestUpperBound(memberType);
            if (lub is null) {
                throw new Exception(format("No common supertype for %s and %s",
                        (*componentType).toString(), memberType.toString()));
            }
            componentType = &lub;
        }
        super(*componentType, size);
    }

    public override bool specializableTo(immutable Type type, TypeConversionChain conversions) {
        if (convertibleTo(type, conversions)) {
            return true;
        }
        // Only allow specialization to array types
        auto arrayType = cast(immutable ArrayType) type;
        if (arrayType is null) {
            return false;
        }
        // Each member must be specializable to the component type
        auto componentType = arrayType.componentType;
        foreach (memberType; _memberTypes) {
            auto literalMemberType = cast(immutable LiteralType) memberType;
            bool convertible;
            auto ignored = new TypeConversionChain();
            if (literalMemberType !is null) {
                convertible = literalMemberType.specializableTo(componentType, ignored);
            } else {
                convertible = memberType.convertibleTo(componentType, ignored);
            }
            if (!convertible) {
                return false;
            }
        }
        conversions.thenReferenceNarrowing();
        return true;
    }

    public override bool opEquals(immutable Type type) {
        auto sizedArrayType = type.exactCastImmutable!SizedArrayLiteralType();
        return sizedArrayType !is null && sizedArrayType.componentType.opEquals(componentType);

    }
}

public immutable class StringLiteralType : SizedArrayType, LiteralType {
    public dstring value;
    private ulong utf8Length;
    private ulong utf16Length;

    public this(dstring value) {
        super(AtomicType.UINT32, value.length);
        this.value = value;
        utf8Length = value.codeLength!char;
        utf16Length = value.codeLength!wchar;
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
            if (literalLength < value.length && value[0 .. literalLength] == literalType.value[0 .. literalLength]) {
                conversions.thenReferenceWidening();
                return true;
            }
            return false;
        }
        // Allow sized array conversions
        return super.convertibleTo(type, conversions);
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
        // There is a lowest upper bound with a string
        auto stringLiteralType = cast(immutable StringLiteralType) other;
        if (stringLiteralType is null) {
            // Otherwise try the sized array LUB
            return super.lowestUpperBound(other);
        }
        // Return the shortest matching prefix
        size_t longest = 0;
        foreach (i, c; value) {
            if (i >= stringLiteralType.value.length || c != stringLiteralType.value[i]) {
                break;
            }
            longest += 1;
        }
        return new immutable StringLiteralType(value[0 .. longest]);
    }

    public override immutable(Type) getMemberType(ulong index) {
        return index >= value.length ? null : new immutable UnsignedIntegerLiteralType(value[index]);
    }

    public override string toString() {
        return format("string_lit(\"%s\")", value);
    }

    public override bool opEquals(immutable Type type) {
        auto literalType = type.exactCastImmutable!StringLiteralType();
        return literalType !is null && value == literalType.value;
    }
}

public immutable struct TypeIdentity {
    public enum Kind {
        TUPLE, STRUCT, ARRAY
    }

    public size_t dataSize;
    public size_t[] memberOffsetByIndex;
    public size_t[string] memberOffsetByName;
    public size_t componentSize;
    public TypeIdentity.Kind kind;
}

public TypeIdentity identity(immutable ReferenceType type) {
    auto tuple = cast(immutable TupleType) type;
    if (tuple !is null) {
        return tuple.tupleIdentity();
    }
    auto array = cast(immutable ArrayType) type;
    if (array !is null) {
        return array.arrayIdentity();
    }
    auto any = cast(immutable AnyType) type;
    if (any !is null) {
        return immutable TypeIdentity(0, [], null, 0, TypeIdentity.Kind.TUPLE);
    }
    assert (0);
}

private TypeIdentity tupleIdentity(immutable TupleType type) {
    size_t dataSize = 0;
    auto offsets = new size_t[type.memberTypes.length];
    foreach (i, memberType; type.memberTypes) {
        auto memberSize = memberType.getStorageSize();
        dataSize = dataSize.alignOffset!size_t(memberSize);
        offsets[i] = dataSize;
        dataSize += memberSize;
    }
    TypeIdentity.Kind kind;
    size_t[string] names;
    auto structType = cast(immutable StructureType) type;
    if (structType !is null) {
        kind = TypeIdentity.Kind.STRUCT;
        foreach (i, name; structType.memberNames) {
            names[name] = offsets[i];
        }
    } else {
        kind = TypeIdentity.Kind.TUPLE;
        names = null;
    }
    return immutable TypeIdentity(dataSize, offsets.idup, names.assumeUnique(), 0, kind);
}

private TypeIdentity arrayIdentity(immutable ArrayType type) {
    // Since arrays are dynamically allocated, only the size of the length field is known
    enum lengthFieldSize = size_t.sizeof;
    return immutable TypeIdentity(lengthFieldSize, [0, lengthFieldSize], null,
            type.componentType.getStorageSize(), TypeIdentity.Kind.ARRAY);
}

private size_t getStorageSize(immutable Type type) {
    // For atomic type use the bit count
    auto atomic = cast(immutable AtomicType) type;
    if (atomic !is null) {
        size_t size = atomic.bitCount;
        // The smallest storable size is 8 bits (for bool)
        if (size < 8) {
            size = 8;
        }
        return size / 8;
    }
    // For reference types, use the native word size
    auto referenceType = cast(immutable ReferenceType) type;
    if (referenceType !is null) {
        return size_t.sizeof;
    }
    assert (0);
}

private size_t alignOffset(Word)(size_t offset, size_t dataSize) {
    // We must pad the offset to make it a multiple of dataSize or Word size, whichever is smaller
    auto alignSize = dataSize < Word.sizeof ? dataSize : Word.sizeof;
    auto remainder = offset % alignSize;
    if (remainder > 0) {
        offset += alignSize - remainder;
    }
    return offset;
}

unittest {
    assert (alignOffset!long(0, 1) == 0);
    assert (alignOffset!long(0, 2) == 0);
    assert (alignOffset!long(0, 4) == 0);
    assert (alignOffset!long(0, 8) == 0);

    assert (alignOffset!long(1, 1) == 1);
    assert (alignOffset!long(1, 2) == 2);
    assert (alignOffset!long(1, 4) == 4);
    assert (alignOffset!long(1, 8) == 8);

    assert (alignOffset!long(2, 1) == 2);
    assert (alignOffset!long(2, 2) == 2);
    assert (alignOffset!long(2, 4) == 4);
    assert (alignOffset!long(2, 8) == 8);

    assert (alignOffset!long(4, 1) == 4);
    assert (alignOffset!long(4, 2) == 4);
    assert (alignOffset!long(4, 4) == 4);
    assert (alignOffset!long(4, 8) == 8);

    assert (alignOffset!long(8, 1) == 8);
    assert (alignOffset!long(8, 2) == 8);
    assert (alignOffset!long(8, 4) == 8);
    assert (alignOffset!long(8, 8) == 8);

    assert (alignOffset!long(31, 1) == 31);
    assert (alignOffset!long(31, 2) == 32);
    assert (alignOffset!long(31, 4) == 32);
    assert (alignOffset!long(31, 8) == 32);

    assert (alignOffset!long(33, 1) == 33);
    assert (alignOffset!long(33, 2) == 34);
    assert (alignOffset!long(33, 4) == 36);
    assert (alignOffset!long(33, 8) == 40);

    assert (alignOffset!long(33, 32) == 40);
    assert (alignOffset!long(48, 32) == 48);
}
