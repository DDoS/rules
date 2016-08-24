module ruleslang.evaluation.runtime;

public class Runtime {
    private Stack _stack;

    public this() {
        _stack = new Stack(4 * 1024);
    }

    @property public Stack stack() {
        return _stack;
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

    public void push(T : long)(T data) {
        auto dataByteSize = T.sizeof;
        if (byteIndex + dataByteSize > byteSize) {
            throw new Exception("Stack overflow");
        }
        T* address = cast(T*) (memory + byteIndex);
        *address = data;
        byteIndex += dataByteSize;
    }

    public T pop(T : long)() {
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

        stack.push!int(46);
        assert(stack.byteIndex == 7);

        assert(stack.pop!int() == 46);
        assert(stack.byteIndex == 3);

        assert(stack.pop!short() == 12);
        assert(stack.byteIndex == 1);

        assert(stack.pop!ubyte() == 3);
        assert(stack.byteIndex == 0);
    }
}
