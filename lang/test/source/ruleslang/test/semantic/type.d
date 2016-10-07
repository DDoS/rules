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
    assert(!AtomicType.BOOL.inRange(0));
    assert(!AtomicType.BOOL.inRange(1));

    assert(AtomicType.SINT8.inRange(-128));
    assert(!AtomicType.SINT8.inRange(-128 - 1));
    assert(AtomicType.SINT8.inRange(127));
    assert(!AtomicType.SINT8.inRange(127 + 1));
    assert(!AtomicType.SINT8.inRange(1f));
    assert(AtomicType.UINT8.inRange(0));
    assert(!AtomicType.UINT8.inRange(-1));
    assert(AtomicType.UINT8.inRange(255));
    assert(!AtomicType.UINT8.inRange(255 + 1));
    assert(!AtomicType.UINT8.inRange(1f));

    assert(AtomicType.SINT16.inRange(-32768));
    assert(!AtomicType.SINT16.inRange(-32768 - 1));
    assert(AtomicType.SINT16.inRange(32767));
    assert(!AtomicType.SINT16.inRange(32767 + 1));
    assert(!AtomicType.SINT16.inRange(1f));
    assert(AtomicType.UINT16.inRange(0));
    assert(!AtomicType.UINT16.inRange(-1));
    assert(AtomicType.UINT16.inRange(65535));
    assert(!AtomicType.UINT16.inRange(65535 + 1));
    assert(!AtomicType.UINT16.inRange(1f));

    assert(AtomicType.SINT32.inRange(-2147483648L));
    assert(!AtomicType.SINT32.inRange(-2147483648L - 1));
    assert(AtomicType.SINT32.inRange(2147483647L));
    assert(!AtomicType.SINT32.inRange(2147483647L + 1));
    assert(!AtomicType.SINT32.inRange(1f));
    assert(AtomicType.UINT32.inRange(0));
    assert(!AtomicType.UINT32.inRange(-1));
    assert(AtomicType.UINT32.inRange(4294967295L));
    assert(!AtomicType.UINT32.inRange(4294967295L + 1));
    assert(!AtomicType.UINT32.inRange(1f));

    assert(AtomicType.SINT64.inRange(cast(long) 9223372036854775808uL));
    assert(AtomicType.SINT64.inRange(9223372036854775807L));
    assert(!AtomicType.SINT64.inRange(9223372036854775807uL + 1));
    assert(!AtomicType.SINT64.inRange(1f));
    assert(AtomicType.UINT64.inRange(0));
    assert(!AtomicType.UINT64.inRange(-1));
    assert(AtomicType.UINT64.inRange(18446744073709551615uL));
    assert(!AtomicType.UINT64.inRange(1f));

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
    assertSpecializable(new immutable SignedIntegerLiteralType(65505L), AtomicType.FP32,
        TypeConversion.INTEGER_LITERAL_NARROW, TypeConversion.INTEGER_TO_FLOAT);
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
        TypeConversion.IDENTITY);
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
    assertNotSpecializable(new immutable FloatLiteralType(10.0e40), AtomicType.FP32);
    assertSpecializable(new immutable FloatLiteralType(0.0 / 0.0), AtomicType.FP32,
        TypeConversion.FLOAT_LITERAL_NARROW);
    assertSpecializable(new immutable FloatLiteralType(-1.0 / 0.0), AtomicType.FP32,
        TypeConversion.FLOAT_LITERAL_NARROW);
}

unittest {
    assertSpecializable(new immutable StringLiteralType("1"d), new immutable StringLiteralType("1"d),
        TypeConversion.IDENTITY);
    assertNotSpecializable(new immutable StringLiteralType("1"d), new immutable StringLiteralType("2"d));
    assertNotSpecializable(new immutable StringLiteralType("1"d), new immutable StringLiteralType("11"d));
    assertSpecializable(new immutable StringLiteralType("11"d), new immutable StringLiteralType("1"d),
        TypeConversion.REFERENCE_WIDENING);
    assertNotSpecializable(new immutable StringLiteralType("21"d), new immutable StringLiteralType("1"d));
    assertSpecializable(new immutable StringLiteralType("12"d), new immutable StringLiteralType("1"d),
        TypeConversion.REFERENCE_WIDENING);
    assertNotSpecializable(new immutable StringLiteralType("ç"d), AtomicType.UINT8);
    assertNotSpecializable(new immutable StringLiteralType("11"d), AtomicType.UINT8);
    assertNotSpecializable(new immutable StringLiteralType("Ʃ"d), AtomicType.UINT8);
    assertSpecializable(new immutable StringLiteralType("Ʃ"d), AnyType.INSTANCE,
            TypeConversion.REFERENCE_WIDENING);
    assertSpecializable(new immutable StringLiteralType("1"d), new immutable SizedArrayType(AtomicType.UINT32, 1),
        TypeConversion.IDENTITY);
    assertSpecializable(new immutable StringLiteralType("1"d), new immutable SizedArrayType(AtomicType.UINT16, 1),
        TypeConversion.STRING_LITERAL_TO_UTF16, TypeConversion.IDENTITY);
    assertSpecializable(new immutable StringLiteralType("1"d), new immutable SizedArrayType(AtomicType.UINT8, 1),
        TypeConversion.STRING_LITERAL_TO_UTF8, TypeConversion.IDENTITY);
    assertNotSpecializable(new immutable StringLiteralType("1"d), new immutable SizedArrayType(AtomicType.UINT8, 2));
    assertSpecializable(new immutable StringLiteralType("1"d), new immutable SizedArrayType(AtomicType.UINT32, 0),
        TypeConversion.REFERENCE_WIDENING);
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
        TypeConversion.STRING_LITERAL_TO_UTF8, TypeConversion.REFERENCE_WIDENING);
    assertSpecializable(new immutable StringLiteralType("Ʃ"d), new immutable SizedArrayType(AtomicType.UINT8, 2),
        TypeConversion.STRING_LITERAL_TO_UTF8, TypeConversion.IDENTITY);
    assertNotSpecializable(new immutable StringLiteralType("Ʃ"d), new immutable SizedArrayType(AtomicType.UINT8, 3));
}

unittest {
    assertConvertible(VoidType.INSTANCE, VoidType.INSTANCE, TypeConversion.IDENTITY);
    assertNotConvertible(VoidType.INSTANCE, AtomicType.UINT8);
    assertNotConvertible(AtomicType.UINT8, VoidType.INSTANCE);
    assertNotConvertible(VoidType.INSTANCE, new immutable ArrayType(AtomicType.UINT8));
}

unittest {
    assertConvertible(new immutable ArrayType(AtomicType.UINT8), new immutable ArrayType(AtomicType.UINT8),
        TypeConversion.IDENTITY);
    assertNotConvertible(new immutable ArrayType(AtomicType.UINT8), new immutable ArrayType(AtomicType.SINT16));
    assertNotConvertible(new immutable ArrayType(new immutable ArrayType(AtomicType.UINT8)),
            new immutable ArrayType(AtomicType.UINT8));
    assertNotConvertible(new immutable ArrayType(AtomicType.UINT8),
            new immutable ArrayType(new immutable ArrayType(AtomicType.UINT8)));
    assertNotConvertible(new immutable ArrayType(AtomicType.UINT8), new immutable SizedArrayType(AtomicType.UINT8, 0));
    assertConvertible(new immutable ArrayType(AtomicType.UINT8), AnyType.INSTANCE,
            TypeConversion.REFERENCE_WIDENING);
    assertNotConvertible(new immutable SizedArrayType(AtomicType.UINT8, 0), new immutable SizedArrayType(AtomicType.UINT8, 1));
    assertNotConvertible(new immutable SizedArrayType(AtomicType.UINT8, 2), new immutable SizedArrayType(AtomicType.SINT8, 2));
    assertConvertible(new immutable SizedArrayType(AtomicType.UINT8, 1), new immutable SizedArrayType(AtomicType.UINT8, 1),
        TypeConversion.IDENTITY);
    assertNotConvertible(new immutable SizedArrayType(AtomicType.UINT8, 1), new immutable SizedArrayType(AtomicType.SINT8, 1));
    assertConvertible(new immutable SizedArrayType(AtomicType.UINT8, 1), new immutable SizedArrayType(AtomicType.UINT8, 0),
        TypeConversion.REFERENCE_WIDENING);
    assertNotConvertible(new immutable SizedArrayType(AtomicType.UINT8, 1), new immutable SizedArrayType(AtomicType.SINT8, 0));
    assertConvertible(new immutable SizedArrayType(AtomicType.UINT8, 1), new immutable ArrayType(AtomicType.UINT8),
        TypeConversion.REFERENCE_WIDENING);
    assertNotConvertible(new immutable SizedArrayType(AtomicType.UINT8, 1), new immutable ArrayType(AtomicType.SINT8));
    assertNotConvertible(new immutable SizedArrayType(AtomicType.UINT8, 0), AtomicType.UINT8);
    assertNotConvertible(new immutable SizedArrayType(AtomicType.UINT8, 2), AtomicType.UINT8);
    assertNotConvertible(new immutable SizedArrayType(AtomicType.UINT8, 1), AtomicType.SINT8);
    assertConvertible(new immutable SizedArrayType(AtomicType.UINT8, 2), AnyType.INSTANCE,
            TypeConversion.REFERENCE_WIDENING);
}

unittest {
    assertConvertible(NullType.INSTANCE, NullType.INSTANCE, TypeConversion.IDENTITY);
    assertConvertible(NullType.INSTANCE, AnyType.INSTANCE, TypeConversion.REFERENCE_WIDENING);
    assertConvertible(
        NullType.INSTANCE,
        new immutable TupleType([AtomicType.UINT8]),
        TypeConversion.REFERENCE_WIDENING
    );
    assertConvertible(
        NullType.INSTANCE,
        new immutable StructureType([AtomicType.UINT8], ["a"]),
        TypeConversion.REFERENCE_WIDENING
    );
    assertConvertible(
        NullType.INSTANCE,
        new immutable ArrayType(AtomicType.UINT8),
        TypeConversion.REFERENCE_WIDENING
    );
    assertConvertible(
        NullType.INSTANCE,
        new immutable SizedArrayType(AtomicType.UINT8, 1),
        TypeConversion.REFERENCE_WIDENING
    );
    assertNotConvertible(AnyType.INSTANCE, new immutable TupleType([AtomicType.UINT8]));
    assertConvertible(new immutable TupleType([AtomicType.UINT8]), new immutable TupleType([AtomicType.UINT8]),
        TypeConversion.IDENTITY);
    assertConvertible(new immutable TupleType([AtomicType.UINT8, AtomicType.BOOL]), new immutable TupleType([AtomicType.UINT8]),
        TypeConversion.REFERENCE_WIDENING);
    assertNotConvertible(new immutable TupleType([AtomicType.UINT8, AtomicType.BOOL]),
            new immutable TupleType([AtomicType.BOOL]));
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
        new immutable TupleType([new immutable TupleType([AtomicType.UINT8])]),
        AnyType.INSTANCE,
        TypeConversion.REFERENCE_WIDENING
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
    assertNotConvertible(
        new immutable TupleType([AtomicType.UINT8]),
        new immutable StructureType([AtomicType.UINT8], ["a"]),
    );
    assertNotConvertible(
        new immutable TupleType([AtomicType.UINT8]),
        new immutable StructureType([AtomicType.UINT8, AtomicType.BOOL], ["a", "b"]),
    );
    assertNotConvertible(
        new immutable TupleType([AtomicType.UINT8, AtomicType.BOOL]),
        new immutable StructureType([AtomicType.UINT8], ["a"]),
    );
    assertConvertible(
        new immutable StructureType([AtomicType.UINT8], ["a"]),
        new immutable TupleType([AtomicType.UINT8]),
        TypeConversion.REFERENCE_WIDENING
    );
    assertNotConvertible(
        new immutable StructureType([AtomicType.UINT8, AtomicType.SINT8], ["a", "b"]),
        new immutable StructureType([AtomicType.SINT8, AtomicType.UINT8], ["a", "b"])
    );
    assertConvertible(
        new immutable StructureType([AtomicType.UINT8, AtomicType.SINT8], ["a", "b"]),
        new immutable StructureType([AtomicType.SINT8, AtomicType.UINT8], ["b", "a"]),
        TypeConversion.REFERENCE_WIDENING
    );
    assertNotConvertible(
        new immutable StructureType([AtomicType.UINT8, AtomicType.SINT8], ["a", "b"]),
        new immutable TupleType([AtomicType.SINT8, AtomicType.UINT8])
    );
    assertConvertible(
        new immutable StructureType([AtomicType.UINT8, AtomicType.SINT8], ["a", "b"]),
        new immutable TupleType([AtomicType.UINT8, AtomicType.SINT8]),
        TypeConversion.REFERENCE_WIDENING
    );
    assertNotConvertible(
        new immutable TupleType([AtomicType.UINT8, AtomicType.BOOL]),
        new immutable ArrayType(AtomicType.UINT8),
    );
    assertNotConvertible(
        new immutable TupleType([AtomicType.UINT8]),
        new immutable ArrayType(AtomicType.UINT8),
    );
    assertNotConvertible(
        new immutable TupleType([AtomicType.UINT8, AtomicType.UINT8]),
        new immutable ArrayType(AtomicType.UINT8),
    );
    assertNotConvertible(
        new immutable TupleType([AtomicType.UINT8, AtomicType.UINT8]),
        new immutable SizedArrayType(AtomicType.UINT8, 1),
    );
    assertNotConvertible(
        new immutable TupleType([AtomicType.UINT8, AtomicType.UINT8]),
        new immutable SizedArrayType(AtomicType.UINT8, 2),
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

unittest {
    assertNotConvertible(
        new immutable TupleType([NullType.INSTANCE]),
        new immutable TupleType([AtomicType.UINT8])
    );
    assertConvertible(
        new immutable TupleType([NullType.INSTANCE]),
        new immutable TupleType([AnyType.INSTANCE]),
        TypeConversion.REFERENCE_WIDENING
    );
    assertNotConvertible(
        new immutable TupleType([AnyType.INSTANCE]),
        new immutable TupleType([NullType.INSTANCE])
    );
    assertConvertible(
        new immutable TupleType([NullType.INSTANCE]),
        new immutable TupleType([new immutable StructureType([AtomicType.FP32], ["fp"])]),
        TypeConversion.REFERENCE_WIDENING
    );
    assertNotConvertible(
        new immutable StructureType([NullType.INSTANCE], ["a"]),
        new immutable StructureType([AtomicType.UINT8], ["a"])
    );
    assertConvertible(
        new immutable StructureType([NullType.INSTANCE], ["a"]),
        new immutable StructureType([AnyType.INSTANCE], ["a"]),
        TypeConversion.REFERENCE_WIDENING
    );
    assertNotConvertible(
        new immutable StructureType([AnyType.INSTANCE], ["a"]),
        new immutable StructureType([NullType.INSTANCE], ["a"])
    );
    assertConvertible(
        new immutable ArrayType(NullType.INSTANCE),
        new immutable ArrayType(AnyType.INSTANCE),
        TypeConversion.REFERENCE_WIDENING
    );
    assertNotConvertible(
        new immutable ArrayType(AnyType.INSTANCE),
        new immutable ArrayType(NullType.INSTANCE)
    );
    assertConvertible(
        new immutable ArrayType(NullType.INSTANCE),
        new immutable ArrayType(NullType.INSTANCE),
        TypeConversion.IDENTITY
    );
    assertConvertible(
        new immutable SizedArrayType(NullType.INSTANCE, 1),
        new immutable SizedArrayType(AnyType.INSTANCE, 1),
        TypeConversion.REFERENCE_WIDENING
    );
    assertNotConvertible(
        new immutable SizedArrayType(AnyType.INSTANCE, 1),
        new immutable SizedArrayType(NullType.INSTANCE, 1)
    );
    assertConvertible(
        new immutable SizedArrayType(NullType.INSTANCE, 1),
        new immutable SizedArrayType(NullType.INSTANCE, 1),
        TypeConversion.IDENTITY
    );
}

unittest {
    assertSpecializable(
        AnyTypeLiteral.INSTANCE,
        AnyTypeLiteral.INSTANCE,
        TypeConversion.IDENTITY
    );
    assertNotSpecializable(
        AnyTypeLiteral.INSTANCE,
        NullType.INSTANCE
    );
    assertSpecializable(
        AnyTypeLiteral.INSTANCE,
        new immutable TupleType([AtomicType.UINT8]),
        TypeConversion.REFERENCE_NARROWING
    );
    assertSpecializable(
        AnyTypeLiteral.INSTANCE,
        new immutable StructureType([AtomicType.UINT8], ["a"]),
        TypeConversion.REFERENCE_NARROWING
    );
    assertSpecializable(
        AnyTypeLiteral.INSTANCE,
        new immutable SizedArrayType(AtomicType.UINT8, 3),
        TypeConversion.REFERENCE_NARROWING
    );
    assertSpecializable(
        AnyTypeLiteral.INSTANCE,
        new immutable ArrayType(AtomicType.UINT8),
        TypeConversion.REFERENCE_NARROWING
    );
    assertSpecializable(
        new immutable TupleLiteralType([AtomicType.UINT8, AtomicType.UINT8]),
        new immutable TupleType([AtomicType.UINT8]),
        TypeConversion.REFERENCE_WIDENING
    );
    assertNotSpecializable(
        new immutable TupleLiteralType([AtomicType.UINT8, AtomicType.UINT8]),
        NullType.INSTANCE
    );
    assertSpecializable(
        new immutable TupleLiteralType([AtomicType.UINT8]),
        new immutable TupleType([AtomicType.UINT8, AtomicType.UINT8]),
        TypeConversion.REFERENCE_NARROWING
    );
    assertSpecializable(
        new immutable TupleLiteralType([AtomicType.UINT8]),
        new immutable TupleType([AtomicType.UINT16, AtomicType.UINT8]),
        TypeConversion.REFERENCE_NARROWING
    );
    assertNotSpecializable(
        new immutable TupleLiteralType([AtomicType.UINT16]),
        new immutable TupleType([AtomicType.UINT8, AtomicType.UINT8])
    );
    assertSpecializable(
        new immutable TupleLiteralType([new immutable SignedIntegerLiteralType(3)]),
        new immutable TupleType([AtomicType.UINT8, AtomicType.UINT8]),
        TypeConversion.REFERENCE_NARROWING
    );
    assertNotSpecializable(
        new immutable TupleLiteralType([new immutable SignedIntegerLiteralType(-3)]),
        new immutable TupleType([AtomicType.UINT8, AtomicType.UINT8])
    );
    assertNotSpecializable(
        new immutable TupleLiteralType([new immutable SignedIntegerLiteralType(0), new immutable SignedIntegerLiteralType(1)]),
        new immutable TupleType([AtomicType.UINT8])
    );
    assertSpecializable(
        new immutable TupleLiteralType([AtomicType.UINT8]),
        new immutable StructureType([AtomicType.UINT16, AtomicType.UINT8], ["a", "b"]),
        TypeConversion.REFERENCE_NARROWING
    );
    assertSpecializable(
        new immutable TupleLiteralType([AtomicType.UINT8]),
        new immutable ArrayType(AtomicType.UINT16),
        TypeConversion.REFERENCE_NARROWING
    );
    assertNotSpecializable(
        new immutable TupleLiteralType([AtomicType.UINT16]),
        new immutable ArrayType(AtomicType.UINT8)
    );
    assertSpecializable(
        new immutable TupleLiteralType([new immutable SignedIntegerLiteralType(0), new immutable SignedIntegerLiteralType(1)]),
        new immutable ArrayType(AtomicType.UINT16),
        TypeConversion.REFERENCE_NARROWING
    );
    assertNotSpecializable(
        new immutable TupleLiteralType([new immutable SignedIntegerLiteralType(-1), new immutable SignedIntegerLiteralType(1)]),
        new immutable ArrayType(AtomicType.UINT16)
    );
    assertSpecializable(
        new immutable StructureLiteralType([AtomicType.UINT8, AtomicType.UINT8], ["a", "b"]),
        new immutable StructureType([AtomicType.UINT8], ["a"]),
        TypeConversion.REFERENCE_WIDENING
    );
    assertSpecializable(
        new immutable StructureLiteralType([AtomicType.UINT8], ["a"]),
        new immutable StructureType([AtomicType.UINT16], ["a"]),
        TypeConversion.REFERENCE_NARROWING
    );
    assertNotSpecializable(
        new immutable StructureLiteralType([AtomicType.UINT8], ["a"]),
        new immutable TupleType([AtomicType.UINT16])
    );
    assertSpecializable(
        new immutable StructureLiteralType([AtomicType.UINT8], ["a"]),
        new immutable StructureType([AtomicType.UINT8, AtomicType.UINT8], ["a", "b"]),
        TypeConversion.REFERENCE_NARROWING
    );
    assertSpecializable(
        new immutable StructureLiteralType([AtomicType.UINT8], ["a"]),
        new immutable StructureType([AtomicType.UINT8, AtomicType.UINT16], ["b", "a"]),
        TypeConversion.REFERENCE_NARROWING
    );
    assertNotSpecializable(
        new immutable StructureLiteralType([AtomicType.UINT16], ["a"]),
        new immutable StructureType([AtomicType.UINT16, AtomicType.UINT8], ["b", "a"])
    );
    assertSpecializable(
        new immutable StructureLiteralType([new immutable SignedIntegerLiteralType(3)], ["b"]),
        new immutable StructureType([AtomicType.UINT8, AtomicType.UINT8], ["b", "a"]),
        TypeConversion.REFERENCE_NARROWING
    );
    assertNotSpecializable(
        new immutable StructureLiteralType([new immutable SignedIntegerLiteralType(-3)], ["b"]),
        new immutable StructureType([AtomicType.UINT8, AtomicType.UINT8], ["b", "a"])
    );
    assertNotSpecializable(
        new immutable StructureLiteralType(
            [new immutable SignedIntegerLiteralType(0), new immutable SignedIntegerLiteralType(1)],
            ["b", "a"]
        ),
        new immutable StructureType([AtomicType.UINT8], ["b"])
    );
    assertSpecializable(
        new immutable StructureLiteralType(
            [new immutable SignedIntegerLiteralType(-1), new immutable SignedIntegerLiteralType(1)],
            ["a", "b"]
        ),
        new immutable StructureType([AtomicType.SINT8, AtomicType.UINT8], ["a", "b"]),
        TypeConversion.REFERENCE_NARROWING
    );
    assertNotSpecializable(
        new immutable StructureLiteralType(
            [new immutable SignedIntegerLiteralType(-1), new immutable SignedIntegerLiteralType(1)],
            ["a", "b"]
        ),
        new immutable StructureType([AtomicType.SINT8, AtomicType.UINT8], ["b", "a"])
    );
    assertSpecializable(
        new immutable SizedArrayLiteralType([AtomicType.UINT8, AtomicType.UINT8], 2),
        new immutable SizedArrayType(AtomicType.UINT8, 2),
        TypeConversion.IDENTITY
    );
    assertSpecializable(
        new immutable SizedArrayLiteralType([AtomicType.UINT8], 1),
        new immutable SizedArrayType(AtomicType.UINT16, 1),
        TypeConversion.REFERENCE_NARROWING
    );
    assertSpecializable(
        new immutable SizedArrayLiteralType([AtomicType.UINT8], 1),
        new immutable ArrayType(AtomicType.UINT16),
        TypeConversion.REFERENCE_NARROWING
    );
    assertNotSpecializable(
        new immutable SizedArrayLiteralType([AtomicType.UINT8], 2),
        new immutable SizedArrayType(AtomicType.UINT16, 1)
    );
    assertSpecializable(
        new immutable SizedArrayLiteralType([AtomicType.UINT8], 2),
        new immutable ArrayType(AtomicType.UINT16),
        TypeConversion.REFERENCE_NARROWING
    );
    assertSpecializable(
        new immutable SizedArrayLiteralType([new immutable SignedIntegerLiteralType(3)], 1),
        new immutable SizedArrayType(AtomicType.UINT8, 1),
        TypeConversion.REFERENCE_NARROWING
    );
    assertNotSpecializable(
        new immutable SizedArrayLiteralType([new immutable SignedIntegerLiteralType(-3)], 1),
        new immutable SizedArrayType(AtomicType.UINT8, 1)
    );
    assertNotSpecializable(
        new immutable SizedArrayLiteralType([new immutable SignedIntegerLiteralType(-3)], 1),
        new immutable ArrayType(AtomicType.UINT8)
    );
    assertSpecializable(
        new immutable SizedArrayLiteralType(
            [new immutable SignedIntegerLiteralType(0), new immutable SignedIntegerLiteralType(1)], 2
        ),
        new immutable SizedArrayType(AtomicType.UINT8, 3),
        TypeConversion.REFERENCE_NARROWING
    );
    assertNotSpecializable(
        new immutable SizedArrayLiteralType(
            [new immutable SignedIntegerLiteralType(-1), new immutable SignedIntegerLiteralType(1)], 2
        ),
        new immutable SizedArrayType(AtomicType.UINT8, 2)
    );
}

unittest {
    assertLUB(VoidType.INSTANCE, VoidType.INSTANCE, VoidType.INSTANCE);
    assertNoLUB(VoidType.INSTANCE, AtomicType.SINT16);
    assertLUB(AtomicType.BOOL, AtomicType.BOOL, AtomicType.BOOL);
    assertLUB(AtomicType.UINT8, AtomicType.SINT8, AtomicType.SINT16);
    assertLUB(AtomicType.UINT64, AtomicType.SINT64, AtomicType.FP64);
    assertLUB(AtomicType.SINT16, AtomicType.SINT64, AtomicType.SINT64);
    assertNoLUB(AtomicType.SINT16, AtomicType.BOOL);
    assertNoLUB(AtomicType.SINT16, NullType.INSTANCE);
    assertLUB(AtomicType.BOOL, new immutable BooleanLiteralType(true), AtomicType.BOOL);
    assertLUB(new immutable BooleanLiteralType(true), new immutable BooleanLiteralType(true),
            new immutable BooleanLiteralType(true));
    assertLUB(new immutable BooleanLiteralType(false), new immutable BooleanLiteralType(true), AtomicType.BOOL);
    assertLUB(new immutable SignedIntegerLiteralType(1), new immutable SignedIntegerLiteralType(1),
            new immutable SignedIntegerLiteralType(1));
    assertLUB(new immutable SignedIntegerLiteralType(1), new immutable SignedIntegerLiteralType(2), AtomicType.SINT64);
    assertLUB(new immutable SignedIntegerLiteralType(1), AtomicType.FP64, AtomicType.FP64);
    assertLUB(new immutable UnsignedIntegerLiteralType(1), AtomicType.UINT8, AtomicType.UINT64);
    assertLUB(new immutable SignedIntegerLiteralType(1), AtomicType.SINT8, AtomicType.SINT64);
    assertLUB(new immutable SignedIntegerLiteralType(1), AtomicType.UINT8, AtomicType.SINT64);
    assertLUB(new immutable SignedIntegerLiteralType(1), AtomicType.UINT64, AtomicType.FP64);
    assertLUB(new immutable UnsignedIntegerLiteralType(1), AtomicType.SINT8, AtomicType.FP64);
    assertLUB(new immutable SignedIntegerLiteralType(1), new immutable UnsignedIntegerLiteralType(1), AtomicType.FP64);
    assertNoLUB(new immutable SignedIntegerLiteralType(1), AtomicType.BOOL);
    assertLUB(new immutable SignedIntegerLiteralType(1), new immutable FloatLiteralType(1),
            new immutable FloatLiteralType(1));
    assertLUB(new immutable FloatLiteralType(1), new immutable FloatLiteralType(1), new immutable FloatLiteralType(1));
    assertLUB(new immutable FloatLiteralType(1), new immutable FloatLiteralType(2), AtomicType.FP64);
    assertLUB(new immutable StringLiteralType("he"), new immutable StringLiteralType("he"),
            new immutable StringLiteralType("he"));
    assertLUB(new immutable StringLiteralType("hello"), new immutable StringLiteralType("hell"),
            new immutable StringLiteralType("hell"));
    assertLUB(new immutable StringLiteralType("hello"d), new immutable StringLiteralType("allo"d),
            new immutable SizedArrayType(AtomicType.UINT32, 4));
    assertLUB(new immutable ArrayType(AtomicType.SINT16), new immutable SizedArrayType(AtomicType.SINT16, 3),
            new immutable ArrayType(AtomicType.SINT16));
    assertLUB(new immutable ArrayType(AtomicType.SINT16), new immutable SizedArrayType(AtomicType.SINT8, 3),
            AnyType.INSTANCE);
    assertLUB(new immutable SizedArrayType(AtomicType.SINT16, 1), new immutable SizedArrayType(AtomicType.SINT16, 3),
            new immutable SizedArrayType(AtomicType.SINT16, 1));
    assertLUB(new immutable SizedArrayType(AtomicType.SINT16, 1), new immutable SizedArrayType(AtomicType.SINT8, 3),
            AnyType.INSTANCE);
    assertLUB(new immutable TupleType([AtomicType.SINT16]), AnyType.INSTANCE, AnyType.INSTANCE);
    assertLUB(new immutable TupleType([AtomicType.SINT16]), NullType.INSTANCE, new immutable TupleType([AtomicType.SINT16]));
    assertLUB(new immutable StructureType([AtomicType.SINT16], ["a"]), AnyType.INSTANCE, AnyType.INSTANCE);
    assertLUB(new immutable StructureType([AtomicType.SINT16], ["a"]), NullType.INSTANCE,
            new immutable StructureType([AtomicType.SINT16], ["a"]));
    assertLUB(new immutable ArrayType(AtomicType.SINT16), AnyType.INSTANCE, AnyType.INSTANCE);
    assertLUB(new immutable ArrayType(AtomicType.SINT16), NullType.INSTANCE, new immutable ArrayType(AtomicType.SINT16));
    assertLUB(new immutable SizedArrayType(AtomicType.SINT16, 1), AnyType.INSTANCE, AnyType.INSTANCE);
    assertLUB(new immutable SizedArrayType(AtomicType.SINT16, 1), NullType.INSTANCE,
            new immutable SizedArrayType(AtomicType.SINT16, 1));
    assertLUB(
        new immutable TupleType(cast(immutable(Type)[]) [AnyType.INSTANCE, AtomicType.SINT16]),
        new immutable TupleType(cast(immutable(Type)[]) [NullType.INSTANCE, AtomicType.BOOL]),
        new immutable TupleType([AnyType.INSTANCE])
    );
    assertLUB(
        new immutable TupleType(cast(immutable(Type)[]) [NullType.INSTANCE, AtomicType.SINT16]),
        new immutable TupleType(cast(immutable(Type)[]) [AnyType.INSTANCE, AtomicType.BOOL]),
        new immutable TupleType([AnyType.INSTANCE])
    );
    assertLUB(
        new immutable StructureType(cast(immutable(Type)[]) [AnyType.INSTANCE, AtomicType.SINT16], ["a", "b"]),
        new immutable StructureType(cast(immutable(Type)[]) [NullType.INSTANCE, AtomicType.BOOL], ["a", "b"]),
        new immutable StructureType([AnyType.INSTANCE], ["a"])
    );
    assertLUB(
        new immutable StructureType(cast(immutable(Type)[]) [NullType.INSTANCE, AtomicType.SINT16], ["a", "b"]),
        new immutable StructureType(cast(immutable(Type)[]) [AnyType.INSTANCE, AtomicType.BOOL], ["a", "b"]),
        new immutable StructureType([AnyType.INSTANCE], ["a"])
    );
    assertLUB(
        new immutable ArrayType(AnyType.INSTANCE),
        new immutable ArrayType(NullType.INSTANCE),
        new immutable ArrayType(AnyType.INSTANCE)
    );
    assertLUB(
        new immutable ArrayType(NullType.INSTANCE),
        new immutable ArrayType(AnyType.INSTANCE),
        new immutable ArrayType(AnyType.INSTANCE)
    );
    assertLUB(
        new immutable SizedArrayType(AnyType.INSTANCE, 1),
        new immutable SizedArrayType(NullType.INSTANCE, 1),
        new immutable SizedArrayType(AnyType.INSTANCE, 1)
    );
    assertLUB(
        new immutable SizedArrayType(NullType.INSTANCE, 1),
        new immutable SizedArrayType(AnyType.INSTANCE, 1),
        new immutable SizedArrayType(AnyType.INSTANCE, 1)
    );
    assertLUB(
        new immutable SizedArrayType(NullType.INSTANCE, 1),
        new immutable ArrayType(AnyType.INSTANCE),
        new immutable ArrayType(AnyType.INSTANCE)
    );
    assertLUB(
        new immutable SizedArrayType(AnyType.INSTANCE, 1),
        new immutable ArrayType(NullType.INSTANCE),
        AnyType.INSTANCE
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

private void assertLUB(immutable Type a, immutable Type b, immutable Type c, string file = __FILE__, size_t line = __LINE__) {
    assert (c !is null);
    auto lub = a.lowestUpperBound(b);
    assert (lub !is null);
    assertEqual(lub, c, file, line);
}

private void assertNoLUB(immutable Type a, immutable Type b, string file = __FILE__, size_t line = __LINE__) {
    auto lub = a.lowestUpperBound(b);
    assertEqual(lub, null);
}
