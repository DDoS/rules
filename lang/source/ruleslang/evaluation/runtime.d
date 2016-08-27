module ruleslang.evaluation.runtime;

import std.format : format;
import std.variant : Variant;
import core.memory : GC;

import ruleslang.semantic.type;
import ruleslang.semantic.symbol;
import ruleslang.semantic.context;

public alias FunctionImpl = void function(Stack);

public abstract class Runtime {
    private Stack _stack;
    private Heap _heap;

    public this() {
        _stack = new Stack(4 * 1024);
        _heap = new Heap(8 * 1024);
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
        auto dataByteSize = T.sizeof;
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

    public void push(T)(immutable AtomicType type, T data) if (is(T : long) || is(T : double)) {
        if (type is AtomicType.BOOL) {
            push!bool(cast(bool) data);
        } else if (type is AtomicType.SINT8) {
            push!byte(cast(byte) data);
        } else if (type is AtomicType.UINT8) {
            push!ubyte(cast(ubyte) data);
        } else if (type is AtomicType.SINT16) {
            push!short(cast(short) data);
        } else if (type is AtomicType.UINT16) {
            push!ushort(cast(ushort) data);
        } else if (type is AtomicType.SINT32) {
            push!int(cast(int) data);
        } else if (type is AtomicType.UINT32) {
            push!uint(cast(uint) data);
        } else if (type is AtomicType.SINT64) {
            push!long(cast(long) data);
        } else if (type is AtomicType.UINT64) {
            push!ulong(cast(ulong) data);
        } else if (type is AtomicType.FP32) {
            push!float(cast(float) data);
        } else if (type is AtomicType.FP64) {
            push!double(cast(double) data);
        } else {
            assert (0);
        }
    }

    public T pop(T)() if (is(T : long) || is(T : double) || is(T == void*)) {
        // Get the data type size
        auto dataByteSize = T.sizeof;
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
        *address = 0;
        // Return the data
        return t;
    }

    public Variant pop(immutable AtomicType type) {
        if (type is AtomicType.BOOL) {
            return Variant(pop!bool);
        }
        if (type is AtomicType.SINT8) {
            return Variant(pop!byte);
        }
        if (type is AtomicType.UINT8) {
            return Variant(pop!ubyte);
        }
        if (type is AtomicType.SINT16) {
            return Variant(pop!short);
        }
        if (type is AtomicType.UINT16) {
            return Variant(pop!ushort);
        }
        if (type is AtomicType.SINT32) {
            return Variant(pop!int);
        }
        if (type is AtomicType.UINT32) {
            return Variant(pop!uint);
        }
        if (type is AtomicType.SINT64) {
            return Variant(pop!long);
        }
        if (type is AtomicType.UINT64) {
            return Variant(pop!ulong);
        }
        if (type is AtomicType.FP32) {
            return Variant(pop!float);
        }
        if (type is AtomicType.FP64) {
            return Variant(pop!double);
        }
        assert (0);
    }

    unittest {
        Stack stack = new Stack(1024);
        assert(stack.byteSize == 1024);

        stack.push!ubyte(3);
        assert(stack.byteIndex == 1);

        stack.push!long(-1);
        assert(stack.byteIndex == 9);

        assert(stack.pop!long() == -1);
        assert(stack.byteIndex == 1);

        stack.push!short(12);
        assert(stack.byteIndex == 3);

        stack.push!double(-129);
        assert(stack.byteIndex == 11);

        stack.push!int(46);
        assert(stack.byteIndex == 15);

        assert(stack.pop!int() == 46);
        assert(stack.byteIndex == 11);

        assert(stack.pop!double() == -129);
        assert(stack.byteIndex == 3);

        assert(stack.pop!short() == 12);
        assert(stack.byteIndex == 1);

        assert(stack.pop!ubyte() == 3);
        assert(stack.byteIndex == 0);

        stack.push(AtomicType.UINT16, 12);
        assert(stack.byteIndex == 2);

        assert(stack.pop(AtomicType.UINT16) == 12);
        assert(stack.byteIndex == 0);
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
