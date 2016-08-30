module ruleslang.evaluation.runtime;

import std.format : format;
import std.variant : Variant;
import core.memory : GC;

import ruleslang.semantic.type;
import ruleslang.semantic.symbol;
import ruleslang.semantic.context;

public alias CompositeHeader = size_t;
public alias FunctionImpl = void function(Stack);

public abstract class Runtime {
    private Stack _stack;
    private Heap _heap;
    private immutable(CompositeInfo)[] composites;

    public this() {
        _stack = new Stack(4 * 1024);
        _heap = new Heap(8 * 1024);
        composites = [];
        composites.reserve(256);
    }

    @property public Stack stack() {
        return _stack;
    }

    @property public Heap heap() {
        return _heap;
    }

    public void call(immutable Function func) {
        call(func.symbolicName);
    }

    public abstract void call(string symbolicName);

    public CompositeHeader registerCompositeInfo(immutable CompositeInfo info) {
        // If it already exists in the list, return the index
        foreach (CompositeHeader i, composite; composites) {
            if (composite == info) {
                return i;
            }
        }
        // Otherwise append it
        composites ~= info;
        return cast(CompositeHeader) composites.length - 1;
    }

    public immutable(CompositeInfo) getCompositeInfo(CompositeHeader index) {
        assert (index < composites.length);
        return composites[index];
    }
}

public class IntrinsicRuntime : Runtime {
    public override void call(string symbolicName) {
        auto func = symbolicName in IntrinsicNameSpace.FUNCTION_IMPLEMENTATIONS;
        if (func is null) {
            throw new Exception(format("Unknown function %s", symbolicName));
        }
        (*func)(stack);
    }
}

public class Stack {
    private void* memory;
    private size_t byteSize;
    private size_t byteIndex;

    public this(size_t byteSize) {
        this.byteSize = byteSize;
        memory = allocateScanned(byteSize);
        byteIndex = 0;
    }

    @property public size_t maxSize() {
        return byteSize;
    }

    @property public size_t usedSize() {
        return byteIndex + 1;
    }

    public bool isEmpty() {
        return byteIndex <= 0;
    }

    public void push(T)(T data) if (is(T : long) || is(T : double) || is(T == void*)) {
        // Get the data type size
        enum dataByteSize = alignedSize!(T, size_t);
        // Check for a stack overflow
        if (byteIndex + dataByteSize > byteSize) {
            throw new Exception("Stack overflow");
        }
        // Calculate the address in the stack memory
        T* address = cast(T*) (memory + byteIndex);
        // Set the data
        *address = data;
        // Increase the stack position
        byteIndex += dataByteSize;
    }

    public void push(T)(immutable AtomicType type, T data) {
        if (AtomicType.BOOL.isEquivalent(type)) {
            push!bool(cast(bool) data);
        } else if (AtomicType.SINT8.isEquivalent(type)) {
            push!byte(cast(byte) data);
        } else if (AtomicType.UINT8.isEquivalent(type)) {
            push!ubyte(cast(ubyte) data);
        } else if (AtomicType.SINT16.isEquivalent(type)) {
            push!short(cast(short) data);
        } else if (AtomicType.UINT16.isEquivalent(type)) {
            push!ushort(cast(ushort) data);
        } else if (AtomicType.SINT32.isEquivalent(type)) {
            push!int(cast(int) data);
        } else if (AtomicType.UINT32.isEquivalent(type)) {
            push!uint(cast(uint) data);
        } else if (AtomicType.SINT64.isEquivalent(type)) {
            push!long(cast(long) data);
        } else if (AtomicType.UINT64.isEquivalent(type)) {
            push!ulong(cast(ulong) data);
        } else if (AtomicType.FP32.isEquivalent(type)) {
            push!float(cast(float) data);
        } else if (AtomicType.FP64.isEquivalent(type)) {
            push!double(cast(double) data);
        } else {
            assert (0);
        }
    }

    public T pop(T)() if (is(T : long) || is(T : double) || is(T == void*)) {
        // Get the data type size
        enum dataByteSize = alignedSize!(T, size_t);
        // Check for a stack underflow
        if (byteIndex - dataByteSize < 0) {
            throw new Exception("Stack underflow");
        }
        // Reduce the stack position
        byteIndex -= dataByteSize;
        // Calculate the address in the stack memory
        T* address = cast(T*) (memory + byteIndex);
        // Get the data and clear the memory to help the GC
        T t = *address;
        static if (is(T == void*)) {
            *address = null;
        } else {
            *address = 0;
        }
        // Return the data
        return t;
    }

    public Variant pop(immutable Type type) {
        auto composite = cast(immutable CompositeType) type;
        if (composite !is null) {
            return Variant(pop!(void*));
        }
        if (AtomicType.BOOL.isEquivalent(type)) {
            return Variant(pop!bool());
        }
        if (AtomicType.SINT8.isEquivalent(type)) {
            return Variant(pop!byte());
        }
        if (AtomicType.UINT8.isEquivalent(type)) {
            return Variant(pop!ubyte());
        }
        if (AtomicType.SINT16.isEquivalent(type)) {
            return Variant(pop!short());
        }
        if (AtomicType.UINT16.isEquivalent(type)) {
            return Variant(pop!ushort());
        }
        if (AtomicType.SINT32.isEquivalent(type)) {
            return Variant(pop!int());
        }
        if (AtomicType.UINT32.isEquivalent(type)) {
            return Variant(pop!uint());
        }
        if (AtomicType.SINT64.isEquivalent(type)) {
            return Variant(pop!long());
        }
        if (AtomicType.UINT64.isEquivalent(type)) {
            return Variant(pop!ulong());
        }
        if (AtomicType.FP32.isEquivalent(type)) {
            return Variant(pop!float());
        }
        if (AtomicType.FP64.isEquivalent(type)) {
            return Variant(pop!double());
        }
        assert (0);
    }

    public void popTo(T)(void* to) {
        // Pop the data from the stack
        T t = pop!T();
        // Copy the data to the given location
        *(cast(T*) to) = t;
    }

    public void popTo(immutable Type type, void* to) {
        auto composite = cast(immutable CompositeType) type;
        if (composite !is null) {
            popTo!(void*)(to);
        } else if (AtomicType.BOOL.isEquivalent(type)) {
            popTo!bool(to);
        } else if (AtomicType.SINT8.isEquivalent(type)) {
            popTo!byte(to);
        } else if (AtomicType.UINT8.isEquivalent(type)) {
            popTo!ubyte(to);
        } else if (AtomicType.SINT16.isEquivalent(type)) {
            popTo!short(to);
        } else if (AtomicType.UINT16.isEquivalent(type)) {
            popTo!ushort(to);
        } else if (AtomicType.SINT32.isEquivalent(type)) {
            popTo!int(to);
        } else if (AtomicType.UINT32.isEquivalent(type)) {
            popTo!uint(to);
        } else if (AtomicType.SINT64.isEquivalent(type)) {
            popTo!long(to);
        } else if (AtomicType.UINT64.isEquivalent(type)) {
            popTo!ulong(to);
        } else if (AtomicType.FP32.isEquivalent(type)) {
            popTo!float(to);
        } else if (AtomicType.FP64.isEquivalent(type)) {
            popTo!double(to);
        } else {
            assert (0);
        }
    }

    unittest {
        static if (size_t.sizeof == 8) {
            Stack stack = new Stack(1024);
            assert(stack.byteSize == 1024);

            stack.push!ubyte(3);
            assert(stack.byteIndex == 8);

            stack.push!long(-1);
            assert(stack.byteIndex == 16);

            assert(stack.pop!long() == -1);
            assert(stack.byteIndex == 8);

            stack.push!short(12);
            assert(stack.byteIndex == 16);

            stack.push!double(-129);
            assert(stack.byteIndex == 24);

            stack.push!int(46);
            assert(stack.byteIndex == 32);

            assert(stack.pop!int() == 46);
            assert(stack.byteIndex == 24);

            assert(stack.pop!double() == -129);
            assert(stack.byteIndex == 16);

            assert(stack.pop!short() == 12);
            assert(stack.byteIndex == 8);

            assert(stack.pop!ubyte() == 3);
            assert(stack.byteIndex == 0);

            stack.push(AtomicType.UINT16, 12);
            assert(stack.byteIndex == 8);

            assert(stack.pop(AtomicType.UINT16) == 12);
            assert(stack.byteIndex == 0);
        } else {
            pragma (msg, "The stack test can only be run on a 64 bit machine, skipping it!");
        }
    }
}

public class Heap {
    private void* memory;
    private size_t byteSize;

    public this(size_t byteSize) {
        this.byteSize = byteSize;
        memory = .allocateScanned(byteSize);
    }

    public void* allocateScanned(size_t byteSize) {
        return .allocateScanned(byteSize);
    }

    public void* allocateNotScanned(size_t byteSize) {
        // Memory cannot be moved and is not scanned
        return GC.calloc(byteSize, GC.BlkAttr.NO_MOVE | GC.BlkAttr.NO_SCAN);
    }
}

private void* allocateScanned(size_t byteSize) {
    // Memory cannot be moved and is scanned
    return GC.calloc(byteSize, GC.BlkAttr.NO_MOVE);
}

private size_t alignedSize(Data, Align)() {
    // Add to the Data size to be a multiple of Align
    auto quotient = Data.sizeof / Align.sizeof;
    auto remainder = Data.sizeof % Align.sizeof;
    if (remainder > 0) {
        quotient += 1;
    }
    return quotient * Align.sizeof;
}

unittest {
    assert (alignedSize!(byte, uint) == 4);
    assert (alignedSize!(short, uint) == 4);
    assert (alignedSize!(int, uint) == 4);
    assert (alignedSize!(long, uint) == 8);
    assert (alignedSize!(float, uint) == 4);
    assert (alignedSize!(double, uint) == 8);
}
