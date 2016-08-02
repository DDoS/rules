module ruleslang.test.semantic.function_;

import ruleslang.semantic.type;
import ruleslang.semantic.function_;

unittest {
    assertLessSpecific([AtomicType.UINT8], [AtomicType.UINT8]);
    assertLessSpecific([AtomicType.UINT16], [AtomicType.UINT8]);
    assertMoreSpecific([AtomicType.UINT8], [AtomicType.UINT16]);

    assertLessSpecific([AtomicType.UINT8, AtomicType.UINT8], [AtomicType.UINT8, AtomicType.UINT8]);
    assertLessSpecific([AtomicType.UINT16, AtomicType.UINT8], [AtomicType.UINT8, AtomicType.UINT8]);
    assertLessSpecific([AtomicType.UINT8, AtomicType.UINT16], [AtomicType.UINT8, AtomicType.UINT8]);
    assertMoreSpecific([AtomicType.UINT8, AtomicType.UINT8], [AtomicType.UINT8, AtomicType.UINT16]);
    assertMoreSpecific([AtomicType.UINT8, AtomicType.UINT8], [AtomicType.UINT16, AtomicType.UINT8]);
    assertMoreSpecific([AtomicType.UINT8, AtomicType.UINT8], [AtomicType.UINT16, AtomicType.UINT16]);

    assertLessSpecific([AtomicType.FP32], [AtomicType.UINT32]);
    assertMoreSpecific([AtomicType.UINT32], [AtomicType.FP32]);

    assertLessSpecific([AtomicType.UINT8], [new immutable SizedArrayType(AtomicType.UINT8, 1)]);
    assertMoreSpecific([new immutable SizedArrayType(AtomicType.UINT8, 1)], [AtomicType.UINT8]);

    assertLessSpecific([new immutable SizedArrayType(AtomicType.UINT8, 1)], [new immutable SizedArrayType(AtomicType.UINT8, 2)]);
    assertMoreSpecific([new immutable SizedArrayType(AtomicType.UINT8, 2)], [new immutable SizedArrayType(AtomicType.UINT8, 1)]);

    assertLessSpecific([new immutable ArrayType(AtomicType.UINT8)], [new immutable ArrayType(AtomicType.UINT16)]);
    assertLessSpecific([new immutable ArrayType(AtomicType.UINT16)], [new immutable ArrayType(AtomicType.UINT8)]);
}

private void assertMoreSpecific(immutable Type[] argumentTypesA, immutable Type[] argumentTypesB) {
    assert(isMoreSpecific(argumentTypesA, argumentTypesB));
}

private void assertLessSpecific(immutable Type[] argumentTypesA, immutable Type[] argumentTypesB) {
    assert(!isMoreSpecific(argumentTypesA, argumentTypesB));
}

private bool isMoreSpecific(immutable Type[] argumentTypesA, immutable Type[] argumentTypesB) {
    return new immutable Function("f", AtomicType.UINT8, argumentTypesA)
            .isMoreSpecific(new immutable Function("f", AtomicType.UINT8, argumentTypesB));
}
