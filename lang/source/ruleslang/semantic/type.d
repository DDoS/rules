module ruleslang.semantic.type;

import std.format : format;
import std.algorithm.searching : canFind;
import std.exception : assumeUnique;
import std.math: isNaN, isInfinity;
import std.utf : codeLength;

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
    STRING_LITERAL_TO_UTF16,
    REFERENCE_WIDENING
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

public immutable interface Type {
    public bool convertibleTo(inout Type type, ref TypeConversionChain conversions);
    public immutable(Type) lowestUpperBound(immutable Type other);
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

    public bool inRange(T)(T value) if (__traits(isIntegral, T) || __traits(isFloating, T)) {
        if (fp) {
            // Check if the value fits in this float type range
            static if (__traits(isFloating, T)) {
                // If the value is a float, NaN and infinity are part of the valid range
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

    public override immutable(Type) lowestUpperBound(immutable Type other) {
        return other;
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
    public bool specializableTo(inout Type type, ref TypeConversionChain conversions);
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

    public override bool specializableTo(inout Type type, ref TypeConversionChain conversions) {
        // No possible specializations for literal booleans
        return convertibleTo(type, conversions);
    }

    public override immutable(Type) lowestUpperBound(immutable Type other) {
        return other;
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

        public override bool convertibleTo(inout Type type, ref TypeConversionChain conversions) {
            if (opEquals(type)) {
                conversions.thenIdentity();
                return true;
            }
            // Can cast to a float literal type if converting the value to floating point gives the same value
            auto floatLiteral = type.exactCastImmutable!FloatLiteralType();
            if (floatLiteral !is null && floatLiteral.value == _value) {
                conversions.thenIntegerToFloat();
                return true;
            }
            // Can cast the atomic type
            return getAtomicType().convertibleTo(type, conversions);
        }

        public override bool specializableTo(inout Type type, ref TypeConversionChain conversions) {
            // Can convert to an atomic type if in range
            auto atomic = cast(immutable AtomicType) type;
            if (atomic !is null && atomic.inRange(_value)) {
                if (atomic.isFloat()) {
                    conversions.thenIntegerToFloat();
                    conversions.thenFloatLiteralNarrow();
                } else {
                    conversions.thenIntegerLiteralNarrow();
                }
                return true;
            }
            // Otherwise regular conversion rules apply
            return convertibleTo(type, conversions);
        }

        public override immutable(Type) lowestUpperBound(immutable Type other) {
            return other;
        }

        public override immutable(Value) asValue() {
            return valueOf(_value);
        }

        public override immutable(AtomicType) getAtomicType() {
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

    public override bool convertibleTo(inout Type type, ref TypeConversionChain conversions) {
        if (opEquals(type)) {
            conversions.thenIdentity();
            return true;
        }
        // Can cast the atomic type
        return getAtomicType().convertibleTo(type, conversions);
    }

    public override bool specializableTo(inout Type type, ref TypeConversionChain conversions) {
        // Can cast to an atomic type if in range
        auto atomic = cast(immutable AtomicType) type;
        if (atomic !is null && atomic.inRange(_value)) {
            conversions.thenFloatLiteralNarrow();
            return true;
        }
        // Otherwise regular conversion rules apply
        return convertibleTo(type, conversions);
    }

    public override immutable(Type) lowestUpperBound(immutable Type other) {
        return other;
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

public immutable interface CompositeType : Type {
    public bool hasMoreMembers(ulong count);
    public immutable(Type) getMemberType(ulong index);
}

public immutable class TupleType : CompositeType {
    private Type[] _memberTypes;

    public this(immutable(Type)[] memberTypes) {
        _memberTypes = memberTypes;
    }

    @property public immutable(Type)[] memberTypes() {
        return _memberTypes;
    }

    public override bool convertibleTo(inout Type type, ref TypeConversionChain conversions) {
        // Allow identity conversion is allowed
        if (opEquals(type)) {
            conversions.thenIdentity();
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
            if (otherMemberType !is null && memberType != otherMemberType) {
                return false;
            }
        }
        conversions.thenReferenceWidening();
        return true;
    }

    public override immutable(Type) lowestUpperBound(immutable Type other) {
        return other;
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

    public override bool opEquals(inout Type type) {
        auto tupleType = type.exactCastImmutable!(TupleType);
        return tupleType !is null && tupleType.memberTypes.equals(_memberTypes);
    }
}

public immutable class StructureType : TupleType {
    public static immutable StructureType EMPTY = new immutable StructureType();
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

    public override bool convertibleTo(inout Type type, ref TypeConversionChain conversions) {
        // Allow identity convertion
        if (opEquals(type)) {
            conversions.thenIdentity();
            return true;
        }
        // Can only convert to another structure type if its members are a subset
        auto structureType = cast(immutable StructureType) type;
        if (structureType is null) {
            return false;
        }
        auto otherMemberNames = structureType.memberNames;
        if (otherMemberNames.length > memberNames.length) {
            return false;
        }
        foreach (otherName; otherMemberNames) {
            if (getMemberType(otherName) is null) {
                return false;
            }
        }
        conversions.thenReferenceWidening();
        return true;
    }

    public override immutable(Type) lowestUpperBound(immutable Type other) {
        return other;
    }

    public override string toString() {
        return format("{%s}", stringZip!": "(_memberNames, memberTypes).join!", "());
    }

    public override bool opEquals(inout Type type) {
        auto structureType = type.exactCastImmutable!(StructureType);
        return structureType !is null && structureType.memberNames == _memberNames
                && structureType.memberTypes.equals(memberTypes);
    }
}

private bool equals(immutable(Type)[] as, immutable(Type)[] bs) {
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

    public override bool convertibleTo(inout Type type, ref TypeConversionChain conversions) {
        // Only identity conversion is allowed
        if (opEquals(type)) {
            conversions.thenIdentity();
            return true;
        }
        return false;
    }

    public override immutable(Type) lowestUpperBound(immutable Type other) {
        return other;
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

    public override immutable(Type) lowestUpperBound(immutable Type other) {
        return other;
    }

    public override bool hasMoreMembers(ulong count) {
        return _size > count;
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
        return super.convertibleTo(type, conversions);
    }

    public override bool specializableTo(inout Type type, ref TypeConversionChain conversions) {
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
        // Otherwise regular conversion rules apply
        return convertibleTo(type, conversions);
    }

    public override immutable(Type) lowestUpperBound(immutable Type other) {
        return other;
    }

    public override string toString() {
        return format("string_lit(\"%s\")", _value);
    }

    mixin literalTypeOpEquals!StringLiteralType;
}
