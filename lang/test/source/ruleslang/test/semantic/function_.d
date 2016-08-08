module ruleslang.test.semantic.function_;

import ruleslang.semantic.type;
import ruleslang.semantic.function_;
import ruleslang.evaluation.value;

unittest {
    assertIsApplicable([], []);
    assertNotApplicable([AtomicType.UINT8], []);
    assertNotApplicable([], [AtomicType.UINT8]);
    assertIsApplicable([AtomicType.UINT8], [AtomicType.UINT8]);
    assertIsApplicable([AtomicType.UINT16], [AtomicType.UINT8]);
    assertNotApplicable([AtomicType.UINT8], [AtomicType.UINT16]);

    assertIsApplicable([AtomicType.UINT8, AtomicType.UINT8], [AtomicType.UINT8, AtomicType.UINT8]);
    assertIsApplicable([AtomicType.UINT16, AtomicType.UINT8], [AtomicType.UINT8, AtomicType.UINT8]);
    assertIsApplicable([AtomicType.UINT8, AtomicType.UINT16], [AtomicType.UINT8, AtomicType.UINT8]);
    assertIsApplicable([AtomicType.UINT16, AtomicType.UINT16], [AtomicType.UINT8, AtomicType.UINT8]);
    assertNotApplicable([AtomicType.UINT8, AtomicType.UINT8], [AtomicType.UINT16, AtomicType.UINT8]);
    assertNotApplicable([AtomicType.UINT8, AtomicType.UINT8], [AtomicType.UINT8, AtomicType.UINT16]);
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
    assertMoreSpecific([new immutable SizedArrayType(AtomicType.UINT8, 1)], [AtomicType.UINT8]);

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
    return new immutable Function("f", parameterTypesA, AtomicType.UINT8, &noop)
            .isMoreSpecific(new immutable Function("f", parameterTypesB, AtomicType.UINT8, &noop));
}

private void assertIsApplicable(immutable Type[] parameterTypes, immutable Type[] argumentTypes) {
    assert(isApplicable(parameterTypes, argumentTypes));
}

private void assertNotApplicable(immutable Type[] parameterTypes, immutable Type[] argumentTypes) {
    assert(!isApplicable(parameterTypes, argumentTypes));
}

private bool isApplicable(immutable Type[] parameterTypes, immutable Type[] argumentTypes) {
    return new immutable Function("f", parameterTypes, AtomicType.UINT8, &noop).isApplicable(argumentTypes);
}

private immutable(Value) noop(immutable(Value)[] arguments) {
    return valueOf(0);
}
