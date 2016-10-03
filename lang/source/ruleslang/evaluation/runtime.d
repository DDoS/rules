module ruleslang.evaluation.runtime;

import std.format : format;
import std.variant : Variant;
import core.memory : GC;

import ruleslang.semantic.type;
import ruleslang.semantic.symbol;
import ruleslang.semantic.context;
import ruleslang.util;

public alias TypeIndex = size_t;
public alias FunctionImpl = void function(Runtime, immutable Function);

public abstract class Runtime {
    private Stack _stack;
    private Heap _heap;
    private immutable(ReferenceType)[] types;
    private void*[string] fieldsByName;

    public this() {
        _stack = new Stack(4 * 1024);
        _heap = new Heap();
    }

    @property public Stack stack() {
        return _stack;
    }

    @property public Heap heap() {
        return _heap;
    }

    public abstract void call(immutable Function func);

    public TypeIndex registerType(immutable ReferenceType type) {
        // If it already exists in the list, return the index
        foreach (TypeIndex index, registeredType; types) {
            if (registeredType.opEquals(type)) {
                return index;
            }
        }
        // Otherwise append it
        types ~= type;
        return cast(TypeIndex) (types.length - 1);
    }

    public immutable(ReferenceType) getType(TypeIndex index) {
        assert (index < types.length);
        return types[index];
    }

    public void registerField(immutable Field field, void* address) {
        fieldsByName[field.symbolicName] = address;
    }

    public void* getField(immutable Field field) {
        return fieldsByName[field.symbolicName];
    }

    public void deleteField(immutable Field field) {
        fieldsByName.remove(field.symbolicName);
    }

    public void* allocateComposite(immutable ReferenceType type) {
        auto dataLayout = type.getDataLayout();
        assert (dataLayout.kind == DataLayout.Kind.TUPLE || dataLayout.kind == DataLayout.Kind.STRUCT);
        // Register the type identity
        auto typeIndex = registerType(type);
        // Calculate the size of the composite (header + data) and allocate the memory
        auto size = TypeIndex.sizeof + dataLayout.dataSize;
        auto address = heap.allocateScanned(size);
        // Next set the header
        *(cast (TypeIndex*) address) = typeIndex;
        return address;
    }

    public void* allocateArray(immutable ArrayType type, size_t length) {
        auto dataLayout = type.getDataLayout();
        assert (dataLayout.kind == DataLayout.Kind.ARRAY);
        // Register the type identity
        auto typeIndex = registerType(type);
        // Calculate the size of the array (header + length field + data) and allocate the memory
        auto size = TypeIndex.sizeof + size_t.sizeof + dataLayout.componentSize * length;
        // Reference arrays need to be scanned
        void* address;
        if (cast(immutable ReferenceType) type.componentType !is null) {
            address = heap.allocateScanned(size);
        } else {
            address = heap.allocateNotScanned(size);
        }
        // Next set the header
        *(cast (TypeIndex*) address) = typeIndex;
        // Finally set the length field
        *(cast (size_t*) (address + TypeIndex.sizeof)) = length;
        return address;
    }
}

public class IntrinsicRuntime : Runtime {
    public override void call(immutable Function func) {
        auto symbolicName = func.symbolicName;
        auto impl = symbolicName in IntrinsicNameSpace.FUNCTION_IMPLEMENTATIONS;
        if (impl is null) {
            throw new Exception(format("Unknown function %s", symbolicName));
        }
        (*impl)(this, func);
    }
}

public class Stack {
    private static enum bool isValidDataType(T) = is(T : long) || is(T : double) || is(T == void*);
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
        return byteIndex;
    }

    public bool isEmpty() {
        return byteIndex <= 0;
    }

    public void push(T)(T data) if (isValidDataType!T) {
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

    public void push(T)(immutable Type type, T data) {
        static if (is(T : long)) {
            if (AtomicType.BOOL.opEquals(type)) {
                push!bool(cast(bool) data);
            } else if (AtomicType.SINT8.opEquals(type)) {
                push!byte(cast(byte) data);
            } else if (AtomicType.UINT8.opEquals(type)) {
                push!ubyte(cast(ubyte) data);
            } else if (AtomicType.SINT16.opEquals(type)) {
                push!short(cast(short) data);
            } else if (AtomicType.UINT16.opEquals(type)) {
                push!ushort(cast(ushort) data);
            } else if (AtomicType.SINT32.opEquals(type)) {
                push!int(cast(int) data);
            } else if (AtomicType.UINT32.opEquals(type)) {
                push!uint(cast(uint) data);
            } else if (AtomicType.SINT64.opEquals(type)) {
                push!long(cast(long) data);
            } else if (AtomicType.UINT64.opEquals(type)) {
                push!ulong(cast(ulong) data);
            } else {
                assert (0);
            }
        } else static if (is(T : double)) {
            if (AtomicType.FP32.opEquals(type)) {
                push!float(cast(float) data);
            } else if (AtomicType.FP64.opEquals(type)) {
                push!double(cast(double) data);
            } else {
                assert (0);
            }
        } else static if (is(T == void*)) {
            if (cast(immutable ReferenceType) type !is null) {
                push!(void*)(cast(void*) data);
            } else {
                assert (0);
            }
        } else {
            static assert (0);
        }
    }

    public void pushFrom(T)(void* from) {
        // Copy the data from the given location
        T t = *(cast(T*) from);
        // Push the data onto the stack
        push!T(t);
    }

    public void pushFrom(immutable Type type, void* from) {
        mixin (buildTypeSwitch!"pushFrom!($0)(from);");
    }

    public T pop(T)() if (isValidDataType!T) {
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
        mixin (buildTypeSwitch!"return Variant(pop!($0));");
    }

    public void popTo(T)(void* to) {
        // Pop the data from the stack
        T t = pop!T();
        // Copy the data to the given location
        *(cast(T*) to) = t;
    }

    public void popTo(immutable Type type, void* to) {
        mixin (buildTypeSwitch!"popTo!($0)(to);");
    }

    public void* peekAddress(T)() if (isValidDataType!T) {
        auto offset = byteIndex - alignedSize!(T, size_t);
        if (offset < 0) {
            throw new Exception("Stack underflow");
        }
        return memory + offset;
    }

    public void* peekAddress(immutable Type type) {
        mixin (buildTypeSwitch!"return peekAddress!($0);");
    }

    public T peek(T)() if (isValidDataType!T) {
        return *(cast(T*) peekAddress!T());
    }

    public Variant peek(immutable Type type) {
        mixin (buildTypeSwitch!"return Variant(peek!($0));");
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
    public void* allocateScanned(size_t byteSize) {
        return .allocateScanned(byteSize);
    }

    public void* allocateNotScanned(size_t byteSize) {
        // Memory cannot be moved and is not scanned
        return GC.calloc(byteSize, GC.BlkAttr.NO_MOVE | GC.BlkAttr.NO_SCAN);
    }
}

public void writeVariant(Variant variant, void* to) {
    if (variant.type == typeid(void*)) {
        *(cast(void**) to) = variant.get!(void*);
    } else if (variant.type == typeid(bool)) {
        *(cast(bool*) to) = variant.get!bool();
    } else if (variant.type == typeid(byte)) {
        *(cast(byte*) to) = variant.get!byte();
    } else if (variant.type == typeid(ubyte)) {
        *(cast(ubyte*) to) = variant.get!ubyte();
    } else if (variant.type == typeid(short)) {
        *(cast(short*) to) = variant.get!short();
    } else if (variant.type == typeid(ushort)) {
        *(cast(ushort*) to) = variant.get!ushort();
    } else if (variant.type == typeid(int)) {
        *(cast(int*) to) = variant.get!int();
    } else if (variant.type == typeid(uint)) {
        *(cast(uint*) to) = variant.get!uint();
    } else if (variant.type == typeid(long)) {
        *(cast(long*) to) = variant.get!long();
    } else if (variant.type == typeid(ulong)) {
        *(cast(ulong*) to) = variant.get!ulong();
    } else if (variant.type == typeid(float)) {
        *(cast(float*) to) = variant.get!float();
    } else if (variant.type == typeid(double)) {
        *(cast(double*) to) = variant.get!double();
    } else {
        assert (0);
    }
}

private string buildTypeSwitch(string op)() {
    return `
    if (cast(immutable ReferenceType) type !is null) {
        ` ~ op.positionalReplace("void*") ~ `
    } else if (AtomicType.BOOL.opEquals(type)) {
        ` ~ op.positionalReplace("bool") ~ `
    } else if (AtomicType.SINT8.opEquals(type)) {
        ` ~ op.positionalReplace("byte") ~ `
    } else if (AtomicType.UINT8.opEquals(type)) {
        ` ~ op.positionalReplace("ubyte") ~ `
    } else if (AtomicType.SINT16.opEquals(type)) {
        ` ~ op.positionalReplace("short") ~ `
    } else if (AtomicType.UINT16.opEquals(type)) {
        ` ~ op.positionalReplace("ushort") ~ `
    } else if (AtomicType.SINT32.opEquals(type)) {
        ` ~ op.positionalReplace("int") ~ `
    } else if (AtomicType.UINT32.opEquals(type)) {
        ` ~ op.positionalReplace("uint") ~ `
    } else if (AtomicType.SINT64.opEquals(type)) {
        ` ~ op.positionalReplace("long") ~ `
    } else if (AtomicType.UINT64.opEquals(type)) {
        ` ~ op.positionalReplace("ulong") ~ `
    } else if (AtomicType.FP32.opEquals(type)) {
        ` ~ op.positionalReplace("float") ~ `
    } else if (AtomicType.FP64.opEquals(type)) {
        ` ~ op.positionalReplace("double") ~ `
    } else {
        assert (0);
    }
    `;
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
