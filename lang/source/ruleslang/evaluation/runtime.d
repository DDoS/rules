module ruleslang.evaluation.runtime;

import std.format : format;

import ruleslang.semantic.context;

public alias FunctionImpl = void function(Stack);

public class Runtime {
    private Stack _stack;
    private FunctionImpl[string] userFunctions;

    public this() {
        _stack = new Stack(4 * 1024);
    }

    @property public Stack stack() {
        return _stack;
    }

    public void call(string symbolicName) {
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
        memory = new byte[byteSize].ptr;
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

    public void push(T)(T data) if (is(T : long) || is(T : double)) {
        auto dataByteSize = T.sizeof;
        if (byteIndex + dataByteSize > byteSize) {
            throw new Exception("Stack overflow");
        }
        T* address = cast(T*) (memory + byteIndex);
        *address = data;
        byteIndex += dataByteSize;
    }

    public T pop(T)() if (is(T : long) || is(T : double)) {
        auto dataByteSize = T.sizeof;
        if (byteIndex - dataByteSize < 0) {
            throw new Exception("Stack underflow");
        }
        byteIndex -= dataByteSize;
        T* address = cast(T*) (memory + byteIndex);
        return *address;
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
    }
}
