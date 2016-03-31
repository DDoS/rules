module ruleslang.test.semantic.type;

import ruleslang.semantic.type;

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
