module ruleslang.test.semantic.type;

import ruleslang.semantic.type;

import ruleslang.test.assertion;

unittest {
    assert(!AtomicType.BOOL.convertibleTo(AtomicType.UINT16));
    assert(!AtomicType.BOOL.convertibleTo(AtomicType.FP32));
    assert(!AtomicType.SINT16.convertibleTo(AtomicType.UINT16));
    assert(!AtomicType.SINT8.convertibleTo(AtomicType.UINT16));
    assert(!AtomicType.SINT32.convertibleTo(AtomicType.UINT16));
    assert(AtomicType.SINT8.convertibleTo(AtomicType.SINT16));
    assert(AtomicType.FP32.convertibleTo(AtomicType.FP64));
    assert(AtomicType.UINT64.convertibleTo(AtomicType.FP64));
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
    assert(new immutable SignedIntegerLiteralType(323).convertibleTo(AtomicType.UINT16));
    assert(!new immutable SignedIntegerLiteralType(323).convertibleTo(AtomicType.UINT8));
    assert(new immutable SignedIntegerLiteralType(323).convertibleTo(AtomicType.SINT16));
    assert(!new immutable SignedIntegerLiteralType(323).convertibleTo(AtomicType.SINT8));
    assert(!new immutable SignedIntegerLiteralType(-1).convertibleTo(AtomicType.UINT64));
    assert(new immutable UnsignedIntegerLiteralType(127).convertibleTo(AtomicType.SINT8));
    assert(new immutable UnsignedIntegerLiteralType(9223372036854775807L).convertibleTo(AtomicType.SINT64));
    assert(!new immutable UnsignedIntegerLiteralType(9223372036854775808uL).convertibleTo(AtomicType.SINT64));
    assert(new immutable FloatLiteralType(10.0e10).convertibleTo(AtomicType.FP32));
    assert(!new immutable FloatLiteralType(10.0e10).convertibleTo(AtomicType.FP16));
    assert(new immutable FloatLiteralType(0.0 / 0.0).convertibleTo(AtomicType.FP16));
    assert(new immutable FloatLiteralType(-1.0 / 0.0).convertibleTo(AtomicType.FP16));
}

unittest {
    assert(new immutable StringLiteralType("1"d).convertibleTo(AtomicType.UINT8));
    assert(new immutable StringLiteralType("ç"d).convertibleTo(AtomicType.UINT8));
    assert(!new immutable StringLiteralType("11"d).convertibleTo(AtomicType.UINT8));
    assert(!new immutable StringLiteralType("Ʃ"d).convertibleTo(AtomicType.UINT8));
    assert(new immutable StringLiteralType("Ʃ"d).convertibleTo(AtomicType.UINT16));
}
