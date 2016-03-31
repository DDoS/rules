module ruleslang.semantic.type;

import std.algorithm.searching : canFind;
import std.exception : assumeUnique;

import ruleslang.util;

public interface Type {
    public bool convertibleTo(inout Type type);
    public string toString();
}

public const class AtomicType : Type {
    public static const AtomicType BOOL = new const AtomicType("bool");
    public static const AtomicType SINT8 = new const AtomicType("sint8");
    public static const AtomicType UINT8 = new const AtomicType("uint8");
    public static const AtomicType SINT16 = new const AtomicType("sint16");
    public static const AtomicType UINT16 = new const AtomicType("uint16");
    public static const AtomicType SINT32 = new const AtomicType("sint32");
    public static const AtomicType UINT32 = new const AtomicType("uint32");
    public static const AtomicType SINT64 = new const AtomicType("sint64");
    public static const AtomicType UINT64 = new const AtomicType("uint64");
    public static const AtomicType FP16 = new const AtomicType("fp16");
    public static const AtomicType FP32 = new const AtomicType("fp32");
    public static const AtomicType FP64 = new const AtomicType("fp64");
    private static immutable const(AtomicType)[][const(AtomicType)] CONVERSIONS;
    private string name;

    public static this() {
        const(AtomicType)[][const(AtomicType)] subtypes = [
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
    }

    private this(string name) {
        this.name = name;
    }

    public override bool convertibleTo(inout Type type) {
        auto atomic = cast(const(AtomicType)) type;
        if (atomic is null) {
            return false;
        }
        return CONVERSIONS[this].canFind(atomic);
    }

    public override string toString() {
        return name;
    }
}
