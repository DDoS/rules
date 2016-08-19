module ruleslang.test.semantic.symbol;

import ruleslang.semantic.type;
import ruleslang.semantic.symbol;
import ruleslang.evaluation.value;

unittest {
    assertAreApplicable([], []);
    assertNotApplicable([AtomicType.UINT8], []);
    assertNotApplicable([], [AtomicType.UINT8]);
    assertAreApplicable([AtomicType.UINT8], [AtomicType.UINT8]);
    assertAreApplicable([AtomicType.UINT16], [AtomicType.UINT8]);
    assertNotApplicable([AtomicType.UINT8], [AtomicType.UINT16]);

    assertAreApplicable([AtomicType.UINT8, AtomicType.UINT8], [AtomicType.UINT8, AtomicType.UINT8]);
    assertAreApplicable([AtomicType.UINT16, AtomicType.UINT8], [AtomicType.UINT8, AtomicType.UINT8]);
    assertAreApplicable([AtomicType.UINT8, AtomicType.UINT16], [AtomicType.UINT8, AtomicType.UINT8]);
    assertAreApplicable([AtomicType.UINT16, AtomicType.UINT16], [AtomicType.UINT8, AtomicType.UINT8]);
    assertNotApplicable([AtomicType.UINT8, AtomicType.UINT8], [AtomicType.UINT16, AtomicType.UINT8]);
    assertNotApplicable([AtomicType.UINT8, AtomicType.UINT8], [AtomicType.UINT8, AtomicType.UINT16]);
}

private void assertAreApplicable(immutable Type[] parameterTypes, immutable Type[] argumentTypes) {
    assert(areApplicable(parameterTypes, argumentTypes));
}

private void assertNotApplicable(immutable Type[] parameterTypes, immutable Type[] argumentTypes) {
    assert(!areApplicable(parameterTypes, argumentTypes));
}

private bool areApplicable(immutable Type[] parameterTypes, immutable Type[] argumentTypes) {
    ConversionKind[] conversions;
    return new immutable Function("f", parameterTypes, AtomicType.UINT8).areApplicable(argumentTypes, conversions);
}
