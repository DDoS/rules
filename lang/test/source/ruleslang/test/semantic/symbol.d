module ruleslang.test.semantic.symbol;

import ruleslang.semantic.type;
import ruleslang.semantic.symbol;
import ruleslang.evaluation.value;

unittest {
    assertAreConvertible([], []);
    assertNotConvertible([AtomicType.UINT8], []);
    assertNotConvertible([], [AtomicType.UINT8]);
    assertAreConvertible([AtomicType.UINT8], [AtomicType.UINT8]);
    assertAreConvertible([AtomicType.UINT16], [AtomicType.UINT8]);
    assertNotConvertible([AtomicType.UINT8], [AtomicType.UINT16]);

    assertAreConvertible([AtomicType.UINT8, AtomicType.UINT8], [AtomicType.UINT8, AtomicType.UINT8]);
    assertAreConvertible([AtomicType.UINT16, AtomicType.UINT8], [AtomicType.UINT8, AtomicType.UINT8]);
    assertAreConvertible([AtomicType.UINT8, AtomicType.UINT16], [AtomicType.UINT8, AtomicType.UINT8]);
    assertAreConvertible([AtomicType.UINT16, AtomicType.UINT16], [AtomicType.UINT8, AtomicType.UINT8]);
    assertNotConvertible([AtomicType.UINT8, AtomicType.UINT8], [AtomicType.UINT16, AtomicType.UINT8]);
    assertNotConvertible([AtomicType.UINT8, AtomicType.UINT8], [AtomicType.UINT8, AtomicType.UINT16]);
}

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
    assertLessSpecific([new immutable SizedArrayType(AtomicType.UINT8, 1)], [AtomicType.UINT8]);

    assertLessSpecific([new immutable SizedArrayType(AtomicType.UINT8, 1)], [new immutable SizedArrayType(AtomicType.UINT8, 2)]);
    assertMoreSpecific([new immutable SizedArrayType(AtomicType.UINT8, 2)], [new immutable SizedArrayType(AtomicType.UINT8, 1)]);

    assertLessSpecific([new immutable ArrayType(AtomicType.UINT8)], [new immutable ArrayType(AtomicType.UINT16)]);
    assertLessSpecific([new immutable ArrayType(AtomicType.UINT16)], [new immutable ArrayType(AtomicType.UINT8)]);
}

private void assertMoreSpecific(immutable Type[] parameterTypesA, immutable Type[] parameterTypesB) {
    assert(isMoreSpecific(parameterTypesA, parameterTypesB));
}

private void assertLessSpecific(immutable Type[] parameterTypesA, immutable Type[] parameterTypesB) {
    assert(!isMoreSpecific(parameterTypesA, parameterTypesB));
}

private bool isMoreSpecific(immutable Type[] parameterTypesA, immutable Type[] parameterTypesB) {
    return new immutable Function("f", parameterTypesA, AtomicType.UINT8)
            .isMoreSpecific(new immutable Function("f", parameterTypesB, AtomicType.UINT8));
}

private void assertAreConvertible(immutable Type[] parameterTypes, immutable Type[] argumentTypes) {
    assert(areConvertible(parameterTypes, argumentTypes));
}

private void assertNotConvertible(immutable Type[] parameterTypes, immutable Type[] argumentTypes) {
    assert(!areConvertible(parameterTypes, argumentTypes));
}

private bool areConvertible(immutable Type[] parameterTypes, immutable Type[] argumentTypes) {
    return new immutable Function("f", parameterTypes, AtomicType.UINT8).areConvertible(argumentTypes);
}
