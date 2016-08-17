module ruleslang.test.semantic.type;

import ruleslang.semantic.type;

import ruleslang.test.assertion;

unittest {
    assertNotConvertible(AtomicType.BOOL, AtomicType.UINT16);
    assertNotConvertible(AtomicType.BOOL, AtomicType.FP32);
    assertConvertible(AtomicType.BOOL, AtomicType.BOOL, TypeConversion.IDENTITY);
    assertNotConvertible(AtomicType.SINT16, AtomicType.UINT16);
    assertNotConvertible(AtomicType.SINT8, AtomicType.UINT16);
    assertNotConvertible(AtomicType.SINT32, AtomicType.UINT16);
    assertConvertible(AtomicType.SINT8, AtomicType.SINT16, TypeConversion.INTEGER_WIDEN);
    assertConvertible(AtomicType.FP32, AtomicType.FP64, TypeConversion.FLOAT_WIDEN);
    assertConvertible(AtomicType.UINT64, AtomicType.FP64, TypeConversion.INTEGER_TO_FLOAT);
}

unittest {
    assert(AtomicType.SINT8.inRange(-128));
    assert(!AtomicType.SINT8.inRange(-128 - 1));
    assert(AtomicType.SINT8.inRange(127));
    assert(!AtomicType.SINT8.inRange(127 + 1));
    assert(AtomicType.UINT8.inRange(0));
    assert(!AtomicType.UINT8.inRange(-1));
    assert(AtomicType.UINT8.inRange(255));
    assert(!AtomicType.UINT8.inRange(255 + 1));

    assert(AtomicType.SINT16.inRange(-32768));
    assert(!AtomicType.SINT16.inRange(-32768 - 1));
    assert(AtomicType.SINT16.inRange(32767));
    assert(!AtomicType.SINT16.inRange(32767 + 1));
    assert(AtomicType.UINT16.inRange(0));
    assert(!AtomicType.UINT16.inRange(-1));
    assert(AtomicType.UINT16.inRange(65535));
    assert(!AtomicType.UINT16.inRange(65535 + 1));

    assert(AtomicType.SINT32.inRange(-2147483648L));
    assert(!AtomicType.SINT32.inRange(-2147483648L - 1));
    assert(AtomicType.SINT32.inRange(2147483647L));
    assert(!AtomicType.SINT32.inRange(2147483647L + 1));
    assert(AtomicType.UINT32.inRange(0));
    assert(!AtomicType.UINT32.inRange(-1));
    assert(AtomicType.UINT32.inRange(4294967295L));
    assert(!AtomicType.UINT32.inRange(4294967295L + 1));

    assert(AtomicType.SINT64.inRange(cast(long) 9223372036854775808uL));
    assert(AtomicType.SINT64.inRange(9223372036854775807L));
    assert(!AtomicType.SINT64.inRange(9223372036854775807uL + 1));
    assert(AtomicType.UINT64.inRange(0));
    assert(!AtomicType.UINT64.inRange(-1));
    assert(AtomicType.UINT64.inRange(18446744073709551615uL));

    assert(AtomicType.FP16.inRange(-65504.0));
    assert(!AtomicType.FP16.inRange(-65504.0 - 1));
    assert(AtomicType.FP16.inRange(65504.0));
    assert(!AtomicType.FP16.inRange(65504.0 + 1));

    assert(AtomicType.FP32.inRange(-0x1.fffffeP+127f));
    assert(!AtomicType.FP32.inRange(cast(double) -0x1.fffffeP+127f - cast(double) 0x1.0eP+127f));
    assert(AtomicType.FP32.inRange(0x1.fffffeP+127f));
    assert(!AtomicType.FP32.inRange(cast(double) 0x1.fffffeP+127f + cast(double) 0x1.0eP+127f));

    assert(AtomicType.FP64.inRange(-0x1.fffffffffffffP+1023));
    assert(AtomicType.FP64.inRange(0x1.fffffffffffffP+1023));
}

unittest {
    assertSpecializable(new immutable BooleanLiteralType(true), new immutable BooleanLiteralType(true),
        TypeConversion.IDENTITY);
    assertNotSpecializable(new immutable BooleanLiteralType(true), new immutable BooleanLiteralType(false));
    assertNotSpecializable(new immutable BooleanLiteralType(false), new immutable BooleanLiteralType(true));
    assertSpecializable(new immutable BooleanLiteralType(false), new immutable BooleanLiteralType(false),
        TypeConversion.IDENTITY);
    assertSpecializable(new immutable BooleanLiteralType(true), AtomicType.BOOL,
        TypeConversion.IDENTITY);
    assertSpecializable(new immutable BooleanLiteralType(false), AtomicType.BOOL,
        TypeConversion.IDENTITY);
    assertNotSpecializable(new immutable BooleanLiteralType(false), AtomicType.UINT8);
    assertSpecializable(new immutable SignedIntegerLiteralType(323L), new immutable SignedIntegerLiteralType(323L),
        TypeConversion.IDENTITY);
    assertNotSpecializable(new immutable SignedIntegerLiteralType(323L), new immutable SignedIntegerLiteralType(322L));
    assertSpecializable(new immutable SignedIntegerLiteralType(323L), AtomicType.UINT16,
        TypeConversion.INTEGER_LITERAL_NARROW);
    assertSpecializable(new immutable SignedIntegerLiteralType(65504L), AtomicType.FP16,
        TypeConversion.INTEGER_TO_FLOAT, TypeConversion.FLOAT_LITERAL_NARROW);
    assertNotSpecializable(new immutable SignedIntegerLiteralType(65505L), AtomicType.FP16);
    assertSpecializable(new immutable SignedIntegerLiteralType(65505L), AtomicType.FP32,
        TypeConversion.INTEGER_TO_FLOAT, TypeConversion.FLOAT_LITERAL_NARROW);
    assertNotSpecializable(new immutable SignedIntegerLiteralType(323L), AtomicType.UINT8);
    assertSpecializable(new immutable SignedIntegerLiteralType(323L), AtomicType.SINT16,
        TypeConversion.INTEGER_LITERAL_NARROW);
    assertNotSpecializable(new immutable SignedIntegerLiteralType(323L), AtomicType.SINT8);
    assertNotSpecializable(new immutable SignedIntegerLiteralType(-1L), AtomicType.UINT64);
    assertSpecializable(new immutable UnsignedIntegerLiteralType(127UL), new immutable UnsignedIntegerLiteralType(127UL),
        TypeConversion.IDENTITY);
    assertNotSpecializable(new immutable UnsignedIntegerLiteralType(127UL), new immutable UnsignedIntegerLiteralType(126UL));
    assertSpecializable(new immutable UnsignedIntegerLiteralType(127UL), AtomicType.SINT8,
        TypeConversion.INTEGER_LITERAL_NARROW);
    assertSpecializable(new immutable SignedIntegerLiteralType(9223372036854775807L), AtomicType.SINT64,
        TypeConversion.INTEGER_LITERAL_NARROW);
    assertNotSpecializable(new immutable UnsignedIntegerLiteralType(9223372036854775808uL), AtomicType.SINT64);
    assertSpecializable(new immutable UnsignedIntegerLiteralType(12UL), new immutable FloatLiteralType(12),
        TypeConversion.INTEGER_TO_FLOAT);
    assertNotSpecializable(new immutable UnsignedIntegerLiteralType(11UL), new immutable FloatLiteralType(12));
    assertSpecializable(new immutable SignedIntegerLiteralType(-12L), new immutable FloatLiteralType(-12),
        TypeConversion.INTEGER_TO_FLOAT);
    assertSpecializable(new immutable FloatLiteralType(10.0e10), new immutable FloatLiteralType(10.0e10),
        TypeConversion.IDENTITY);
    assertNotSpecializable(new immutable FloatLiteralType(10.0e10), new immutable FloatLiteralType(11.0e10));
    assertSpecializable(new immutable FloatLiteralType(10.0e10), AtomicType.FP32,
        TypeConversion.FLOAT_LITERAL_NARROW);
    assertNotSpecializable(new immutable FloatLiteralType(10.0e10), AtomicType.FP16);
    assertSpecializable(new immutable FloatLiteralType(0.0 / 0.0), AtomicType.FP16,
        TypeConversion.FLOAT_LITERAL_NARROW);
    assertSpecializable(new immutable FloatLiteralType(-1.0 / 0.0), AtomicType.FP16,
        TypeConversion.FLOAT_LITERAL_NARROW);
}

unittest {
    assertSpecializable(new immutable StringLiteralType("1"d), new immutable StringLiteralType("1"d),
        TypeConversion.IDENTITY);
    assertNotSpecializable(new immutable StringLiteralType("1"d), new immutable StringLiteralType("2"d));
    assertNotSpecializable(new immutable StringLiteralType("1"d), new immutable StringLiteralType("11"d));
    assertSpecializable(new immutable StringLiteralType("11"d), new immutable StringLiteralType("1"d),
        TypeConversion.SIZED_ARRAY_SHORTEN);
    assertNotSpecializable(new immutable StringLiteralType("21"d), new immutable StringLiteralType("1"d));
    assertSpecializable(new immutable StringLiteralType("12"d), new immutable StringLiteralType("1"d),
        TypeConversion.SIZED_ARRAY_SHORTEN);
    assertNotSpecializable(new immutable StringLiteralType("ç"d), AtomicType.UINT8);
    assertNotSpecializable(new immutable StringLiteralType("11"d), AtomicType.UINT8);
    assertNotSpecializable(new immutable StringLiteralType("Ʃ"d), AtomicType.UINT8);
    assertSpecializable(new immutable StringLiteralType("1"d), new immutable SizedArrayType(AtomicType.UINT32, 1),
        TypeConversion.IDENTITY);
    assertSpecializable(new immutable StringLiteralType("1"d), new immutable SizedArrayType(AtomicType.UINT16, 1),
        TypeConversion.STRING_LITERAL_TO_UTF16, TypeConversion.IDENTITY);
    assertSpecializable(new immutable StringLiteralType("1"d), new immutable SizedArrayType(AtomicType.UINT8, 1),
        TypeConversion.STRING_LITERAL_TO_UTF8, TypeConversion.IDENTITY);
    assertNotSpecializable(new immutable StringLiteralType("1"d), new immutable SizedArrayType(AtomicType.UINT8, 2));
    assertSpecializable(new immutable StringLiteralType("1"d), new immutable SizedArrayType(AtomicType.UINT32, 0),
        TypeConversion.SIZED_ARRAY_SHORTEN);
    assertNotSpecializable(new immutable StringLiteralType("1"d), new immutable SizedArrayType(AtomicType.UINT32, 2));
    assertSpecializable(new immutable StringLiteralType("11"d), new immutable SizedArrayType(AtomicType.UINT32, 2),
        TypeConversion.IDENTITY);
    assertSpecializable(new immutable StringLiteralType("11"d), new immutable SizedArrayType(AtomicType.UINT16, 2),
        TypeConversion.STRING_LITERAL_TO_UTF16, TypeConversion.IDENTITY);
    assertSpecializable(new immutable StringLiteralType("11"d), new immutable SizedArrayType(AtomicType.UINT8, 2),
        TypeConversion.STRING_LITERAL_TO_UTF8, TypeConversion.IDENTITY);
    assertSpecializable(new immutable StringLiteralType("Ʃ"d), new immutable SizedArrayType(AtomicType.UINT32, 1),
        TypeConversion.IDENTITY);
    assertSpecializable(new immutable StringLiteralType("Ʃ"d), new immutable SizedArrayType(AtomicType.UINT16, 1),
        TypeConversion.STRING_LITERAL_TO_UTF16, TypeConversion.IDENTITY);
    assertSpecializable(new immutable StringLiteralType("Ʃ"d), new immutable SizedArrayType(AtomicType.UINT8, 1),
        TypeConversion.STRING_LITERAL_TO_UTF8, TypeConversion.SIZED_ARRAY_SHORTEN);
    assertSpecializable(new immutable StringLiteralType("Ʃ"d), new immutable SizedArrayType(AtomicType.UINT8, 2),
        TypeConversion.STRING_LITERAL_TO_UTF8, TypeConversion.IDENTITY);
    assertNotSpecializable(new immutable StringLiteralType("Ʃ"d), new immutable SizedArrayType(AtomicType.UINT8, 3));
}

unittest {
    assertConvertible(new immutable ArrayType(AtomicType.UINT8), new immutable ArrayType(AtomicType.UINT8),
        TypeConversion.IDENTITY);
    assertNotConvertible(new immutable ArrayType(AtomicType.UINT8), new immutable ArrayType(AtomicType.SINT16));
    assertNotConvertible(new immutable ArrayType(new immutable ArrayType(AtomicType.UINT8)), new immutable ArrayType(AtomicType.UINT8));
    assertNotConvertible(new immutable ArrayType(AtomicType.UINT8), new immutable ArrayType(new immutable ArrayType(AtomicType.UINT8)));
    assertNotConvertible(new immutable ArrayType(AtomicType.UINT8), new immutable SizedArrayType(AtomicType.UINT8, 0));
    assertNotConvertible(new immutable SizedArrayType(AtomicType.UINT8, 0), new immutable SizedArrayType(AtomicType.UINT8, 1));
    assertNotConvertible(new immutable SizedArrayType(AtomicType.UINT8, 2), new immutable SizedArrayType(AtomicType.SINT8, 2));
    assertConvertible(new immutable SizedArrayType(AtomicType.UINT8, 1), new immutable SizedArrayType(AtomicType.UINT8, 1),
        TypeConversion.IDENTITY);
    assertNotConvertible(new immutable SizedArrayType(AtomicType.UINT8, 1), new immutable SizedArrayType(AtomicType.SINT8, 1));
    assertConvertible(new immutable SizedArrayType(AtomicType.UINT8, 1), new immutable SizedArrayType(AtomicType.UINT8, 0),
        TypeConversion.SIZED_ARRAY_SHORTEN);
    assertNotConvertible(new immutable SizedArrayType(AtomicType.UINT8, 1), new immutable SizedArrayType(AtomicType.SINT8, 0));
    assertConvertible(new immutable SizedArrayType(AtomicType.UINT8, 1), new immutable ArrayType(AtomicType.UINT8),
        TypeConversion.SIZED_ARRAY_TO_UNSIZED);
    assertNotConvertible(new immutable SizedArrayType(AtomicType.UINT8, 1), new immutable ArrayType(AtomicType.SINT8));
    assertNotConvertible(new immutable SizedArrayType(AtomicType.UINT8, 0), AtomicType.UINT8);
    assertNotConvertible(new immutable SizedArrayType(AtomicType.UINT8, 2), AtomicType.UINT8);
    assertNotConvertible(new immutable SizedArrayType(AtomicType.UINT8, 1), AtomicType.SINT8);
}

unittest {
    assertConvertible(new immutable TupleType([]), new immutable TupleType([]),
        TypeConversion.IDENTITY);
    assertConvertible(new immutable TupleType([AtomicType.UINT8]), new immutable TupleType([]),
        TypeConversion.REFERENCE_WIDENING);
    assertNotConvertible(new immutable TupleType([]), new immutable TupleType([AtomicType.UINT8]));
    assertConvertible(new immutable TupleType([AtomicType.UINT8]), new immutable TupleType([AtomicType.UINT8]),
        TypeConversion.IDENTITY);
    assertConvertible(new immutable TupleType([AtomicType.UINT8, AtomicType.BOOL]), new immutable TupleType([AtomicType.UINT8]),
        TypeConversion.REFERENCE_WIDENING);
    assertNotConvertible(new immutable TupleType([AtomicType.UINT8, AtomicType.BOOL]), new immutable TupleType([AtomicType.BOOL]));
    assertConvertible(
        new immutable TupleType([new immutable TupleType([AtomicType.UINT8])]),
        new immutable TupleType([new immutable TupleType([AtomicType.UINT8])]),
        TypeConversion.IDENTITY
    );
    assertNotConvertible(
        new immutable TupleType([new immutable TupleType([AtomicType.UINT8])]),
        new immutable TupleType([new immutable TupleType([AtomicType.UINT8, AtomicType.BOOL])]),
    );
    assertConvertible(
        new immutable StructureType([AtomicType.UINT8], ["a"]),
        new immutable StructureType([AtomicType.UINT8], ["a"]),
        TypeConversion.IDENTITY
    );
    assertNotConvertible(
        new immutable StructureType([AtomicType.UINT8], ["a"]),
        new immutable StructureType([AtomicType.BOOL, AtomicType.UINT8], ["b", "a"]),
    );
    assertConvertible(
        new immutable StructureType([AtomicType.BOOL, AtomicType.UINT8], ["b", "a"]),
        new immutable StructureType([AtomicType.UINT8], ["a"]),
        TypeConversion.REFERENCE_WIDENING
    );
    assertConvertible(
        new immutable TupleType([AtomicType.UINT8]),
        new immutable StructureType([AtomicType.UINT8], ["a"]),
        TypeConversion.REFERENCE_WIDENING
    );
    assertNotConvertible(
        new immutable TupleType([AtomicType.UINT8]),
        new immutable StructureType([AtomicType.UINT8, AtomicType.BOOL], ["a", "b"]),
    );
    assertConvertible(
        new immutable TupleType([AtomicType.UINT8, AtomicType.BOOL]),
        new immutable StructureType([AtomicType.UINT8], ["a"]),
        TypeConversion.REFERENCE_WIDENING
    );
    assertNotConvertible(
        new immutable StructureType([AtomicType.UINT8], ["a"]),
        new immutable TupleType([AtomicType.UINT8]),
    );
    assertNotConvertible(
        new immutable TupleType([AtomicType.UINT8, AtomicType.BOOL]),
        new immutable ArrayType(AtomicType.UINT8),
    );
    assertConvertible(
        new immutable TupleType([AtomicType.UINT8]),
        new immutable ArrayType(AtomicType.UINT8),
        TypeConversion.REFERENCE_WIDENING
    );
    assertConvertible(
        new immutable TupleType([AtomicType.UINT8, AtomicType.UINT8]),
        new immutable ArrayType(AtomicType.UINT8),
        TypeConversion.REFERENCE_WIDENING
    );
    assertConvertible(
        new immutable TupleType([AtomicType.UINT8, AtomicType.UINT8]),
        new immutable SizedArrayType(AtomicType.UINT8, 1),
        TypeConversion.REFERENCE_WIDENING
    );
    assertConvertible(
        new immutable TupleType([AtomicType.UINT8, AtomicType.UINT8]),
        new immutable SizedArrayType(AtomicType.UINT8, 2),
        TypeConversion.REFERENCE_WIDENING
    );
    assertNotConvertible(
        new immutable TupleType([AtomicType.UINT8, AtomicType.UINT8]),
        new immutable SizedArrayType(AtomicType.UINT8, 3),
    );
    assertNotConvertible(
        new immutable StructureType([AtomicType.UINT8], ["a"]),
        new immutable ArrayType(AtomicType.UINT8),
    );
    assertNotConvertible(
        new immutable StructureType([AtomicType.UINT8], ["a"]),
        new immutable SizedArrayType(AtomicType.UINT8, 1),
    );
}

private void assertConvertible(immutable Type from, immutable Type to, TypeConversionChain by...) {
    auto chain = new TypeConversionChain();
    auto convertible = from.convertibleTo(to, chain);
    assert(convertible);
    assertEqual(chain, by);
}

private void assertNotConvertible(immutable Type from, immutable Type to) {
    auto chain = new TypeConversionChain();
    assert(!from.convertibleTo(to, chain));
}

private void assertSpecializable(immutable LiteralType from, immutable Type to, TypeConversionChain by...) {
    auto chain = new TypeConversionChain();
    auto specializable = from.specializableTo(to, chain);
    assert(specializable);
    assertEqual(chain, by);
}

private void assertNotSpecializable(immutable LiteralType from, immutable Type to) {
    auto chain = new TypeConversionChain();
    assert(!from.specializableTo(to, chain));
}
