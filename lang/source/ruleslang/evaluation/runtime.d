module ruleslang.evaluation.runtime;

import core.memory : GC;

import std.format : format;
import std.conv : to;
import std.variant : Variant;
import std.typecons : Nullable;
import std.json;

import ruleslang.semantic.type;
import ruleslang.semantic.symbol;
import ruleslang.semantic.context;
import ruleslang.semantic.tree;
import ruleslang.util;

public alias TypeIndex = size_t;

public interface FunctionImpl {
    public void call(Runtime runtime, immutable Function func);
}

public class Runtime {
    private struct Frame {
        private void*[string] fieldsByName;
        private FunctionImpl[string] functionImplsByName;
        private Variant returnValue;
    }

    private Stack _stack;
    private Heap _heap;
    private immutable(ReferenceType)[] types;
    private Frame[] frames;

    public this() {
        _stack = new Stack(4 * 1024);
        _heap = new Heap();
        frames.reserve(128);
        frames.length = 1;
    }

    @property public Stack stack() {
        return _stack;
    }

    @property public Heap heap() {
        return _heap;
    }

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

    public void newFrame() {
        frames.length++;
    }

    public void discardFrame() {
        assert (frames.length > 0);
        frames.length--;
    }

    public void registerField(immutable Field field, void* address) {
        frames[$ - 1].fieldsByName[field.symbolicName] = address;
    }

    public void* getField(immutable Field field) {
        void** fieldAddress;
        size_t i = frames.length;
        // Go down the call frames to search for the field address
        do {
            i -= 1;
            fieldAddress = field.symbolicName in frames[i].fieldsByName;
        } while (fieldAddress is null && i > 0);
        // Make sure we found a field address
        assert (fieldAddress !is null);
        return *fieldAddress;
    }

    public void deleteField(immutable Field field) {
        frames[$ - 1].fieldsByName.remove(field.symbolicName);
    }

    public void registerFunctionImpl(immutable Function func, FunctionImpl impl) {
        frames[$ - 1].functionImplsByName[func.symbolicName] = impl;
    }

    public void call(immutable Function func) {
        auto symbolicName = func.symbolicName;
        if (func.prefix == IntrinsicNameSpace.PREFIX) {
            auto impl = symbolicName in IntrinsicNameSpace.FUNCTION_IMPLEMENTATIONS;
            assert (impl !is null);
            (*impl)(this, func);
        } else {
            FunctionImpl* impl;
            size_t i = frames.length;
            // Go down the call frames to search for the function implementation
            do {
                i -= 1;
                impl = symbolicName in frames[i].functionImplsByName;
            } while (impl is null && i > 0);
            // Make sure we found a function implementation
            assert (impl !is null);
            (*impl).call(this, func);
        }
    }

    public void deleteFunctionImpl(immutable Function func) {
        frames[$ - 1].functionImplsByName.remove(func.symbolicName);
    }

    @property public void returnValue(Variant value) {
        frames[$ - 1].returnValue = value;
    }

    @property public Variant returnValue() {
        return frames[$ - 1].returnValue;
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

    private bool writeJSONValue(JSONValue value, immutable Type type, void* address) {
        final switch (value.type) with (JSON_TYPE) {
            case NULL:
                return writeJSONNull(value, type, address);
            case STRING:
                return writeJSONString(value, type, address);
            case INTEGER:
                return writeJSONInteger(value, type, address);
            case UINTEGER:
                return writeJSONUinteger(value, type, address);
            case FLOAT:
                return writeJSONFloat(value, type, address);
            case OBJECT:
                return writeJSONObject(value, type, address);
            case ARRAY:
                return writeJSONArray(value, type, address);
            case TRUE:
                return writeJSONTrue(value, type, address);
            case FALSE:
                return writeJSONFalse(value, type, address);
        }
    }

    private bool writeJSONNull(JSONValue json, immutable Type type, void* address) {
        if (NullType.INSTANCE.convertibleTo(type)) {
            *(cast(void**) address) = null;
            return true;
        }
        return false;
    }

    private bool writeJSONString(JSONValue json, immutable Type type, void* address) {
        bool writeString(String)(String str, immutable ArrayType arrayType, void* address) {

            if (auto sizedArrayType = cast(immutable SizedArrayType) arrayType) {
                if (str.length != sizedArrayType.size) {
                    return false;
                }
            }

            auto arrayAddress = allocateArray(arrayType, str.length);
            auto dataSegment = arrayAddress + TypeIndex.sizeof + size_t.sizeof;

            static if (is(String == string)) {
                (cast(char*) dataSegment)[0 .. str.length] = str;
            } else static if (is(String == wstring)) {
                (cast(wchar*) dataSegment)[0 .. str.length] = str;
            } else static if (is(String == dstring)) {
                (cast(dchar*) dataSegment)[0 .. str.length] = str;
            } else {
                static assert (0);
            }
            *(cast(void**) address) = arrayAddress;
            return true;
        }

        if (auto arrayType = cast(immutable ArrayType) type) {
            if (arrayType.componentType == AtomicType.UINT8) {
                return writeString(json.str, arrayType, address);
            }
            if (arrayType.componentType == AtomicType.UINT16) {
                return writeString(json.str.to!wstring, arrayType, address);
            }
            if (arrayType.componentType == AtomicType.UINT32) {
                return writeString(json.str.to!dstring, arrayType, address);
            }
        }
        return false;
    }

    private bool writeJSONInteger(JSONValue json, immutable Type type, void* address) {
        if (type == AtomicType.SINT8) {
            *(cast(byte*) address) = cast(byte) json.integer;
            return true;
        }
        if (type == AtomicType.SINT16) {
            *(cast(short*) address) = cast(short) json.integer;
            return true;
        }
        if (type == AtomicType.SINT32) {
            *(cast(int*) address) = cast(int) json.integer;
            return true;
        }
        if (type == AtomicType.SINT64) {
            *(cast(long*) address) = cast(long) json.integer;
            return true;
        }
        if (type == AtomicType.FP32) {
            *(cast(float*) address) = cast(float) json.integer;
            return true;
        }
        if (type == AtomicType.FP64) {
            *(cast(double*) address) = cast(double) json.integer;
            return true;
        }
        return false;
    }

    private bool writeJSONUinteger(JSONValue json, immutable Type type, void* address) {
        if (type == AtomicType.UINT8) {
            *(cast(ubyte*) address) = cast(ubyte) json.uinteger;
            return true;
        }
        if (type == AtomicType.UINT16) {
            *(cast(ushort*) address) = cast(ushort) json.uinteger;
            return true;
        }
        if (type == AtomicType.UINT32) {
            *(cast(uint*) address) = cast(uint) json.uinteger;
            return true;
        }
        if (type == AtomicType.UINT64) {
            *(cast(ulong*) address) = cast(ulong) json.uinteger;
            return true;
        }
        if (type == AtomicType.FP32) {
            *(cast(float*) address) = cast(float) json.uinteger;
            return true;
        }
        if (type == AtomicType.FP64) {
            *(cast(double*) address) = cast(double) json.uinteger;
            return true;
        }
        return false;
    }

    private bool writeJSONFloat(JSONValue json, immutable Type type, void* address) {
        if (type == AtomicType.FP32) {
            *(cast(float*) address) = cast(float) json.floating;
            return true;
        }
        if (type == AtomicType.FP64) {
            *(cast(double*) address) = cast(double) json.floating;
            return true;
        }
        return false;
    }

    public bool writeJSONObject(JSONValue json, immutable Type type, void* address) {
        auto structType = cast(immutable StructureType) type;
        if (structType is null) {
            return false;
        }

        auto dataLayout = structType.getDataLayout();

        auto structAddress = allocateComposite(structType);
        auto dataSegment = structAddress + TypeIndex.sizeof;

        foreach (string memberName, value; json) {
            auto memberType = structType.getMemberType(memberName);
            if (memberType is null) {
                return false;
            }

            auto memberAddress = dataSegment + dataLayout.memberOffsetByName[memberName];

            if (!writeJSONValue(value, memberType, memberAddress)) {
                return false;
            }
        }
        *(cast(void**) address) = structAddress;
        return true;
    }

    private bool writeJSONArray(JSONValue json, immutable Type type, void* address) {
        auto arrayType = cast(immutable ArrayType) type;
        if (arrayType is null) {
            return false;
        }

        auto length = json.array.length;

        if (auto sizedArrayType = cast(immutable SizedArrayType) arrayType) {
            if (length != sizedArrayType.size) {
                return false;
            }
        }

        auto dataLayout = arrayType.getDataLayout();

        auto arrayAddress = allocateArray(arrayType, length);
        auto dataSegment = arrayAddress + TypeIndex.sizeof + size_t.sizeof;

        auto componentType = arrayType.componentType;

        foreach (size_t index, value; json) {
            auto valueAddress = dataSegment + index * dataLayout.componentSize;

            if (!writeJSONValue(value, componentType, valueAddress)) {
                return false;
            }
        }
        *(cast(void**) address) = arrayAddress;
        return true;
    }

    private bool writeJSONTrue(JSONValue json, immutable Type type, void* address) {
        if (type == AtomicType.BOOL) {
            *(cast(bool*) address) = true;
            return true;
        }
        return false;
    }

    private bool writeJSONFalse(JSONValue json, immutable Type type, void* address) {
        if (type == AtomicType.BOOL) {
            *(cast(bool*) address) = false;
            return true;
        }
        return false;
    }

    public JSONValue readJSONValue(immutable Type type, void* address) {
        if (type == AtomicType.BOOL) {
            return JSONValue(*(cast(bool*) address));
        }
        if (type == AtomicType.SINT8) {
            return JSONValue(*(cast(byte*) address));
        }
        if (type == AtomicType.UINT8) {
            return JSONValue(*(cast(ubyte*) address));
        }
        if (type == AtomicType.SINT16) {
            return JSONValue(*(cast(short*) address));
        }
        if (type == AtomicType.UINT16) {
            return JSONValue(*(cast(ushort*) address));
        }
        if (type == AtomicType.SINT32) {
            return JSONValue(*(cast(int*) address));
        }
        if (type == AtomicType.UINT32) {
            return JSONValue(*(cast(uint*) address));
        }
        if (type == AtomicType.SINT64) {
            return JSONValue(*(cast(long*) address));
        }
        if (type == AtomicType.UINT64) {
            return JSONValue(*(cast(ulong*) address));
        }
        if (type == AtomicType.FP32) {
            return JSONValue(*(cast(float*) address));
        }
        if (type == AtomicType.FP64) {
            return JSONValue(*(cast(double*) address));
        }

        auto referenceAddress = *(cast(void**) address);
        if (referenceAddress is null) {
            return JSONValue(null);
        }

        auto referenceType = getType(*(cast(TypeIndex*) referenceAddress));

        if (auto arrayType = cast(immutable ArrayType) referenceType) {
            auto dataLayout = arrayType.getDataLayout();
            auto length = *(cast(size_t*) (referenceAddress + TypeIndex.sizeof));
            auto dataSegment = referenceAddress + TypeIndex.sizeof + size_t.sizeof;

            auto componentType = arrayType.componentType;
            if (componentType == AtomicType.UINT8) {
                return JSONValue((cast(char*) dataSegment)[0 .. length]);
            }

            JSONValue[] values;
            foreach (index; 0 .. length) {
                auto valueAddress = dataSegment + index * dataLayout.componentSize;
                values ~= readJSONValue(componentType, valueAddress);
            }
            return JSONValue(values);
        }

        if (auto structType = cast(immutable StructureType) referenceType) {
            auto dataLayout = structType.getDataLayout();
            auto dataSegment = referenceAddress + TypeIndex.sizeof;

            JSONValue[string] values;
            foreach (memberName; structType.memberNames) {
                auto memberType = structType.getMemberType(memberName);
                auto memberAddress = dataSegment + dataLayout.memberOffsetByName[memberName];
                values[memberName] = readJSONValue(memberType, memberAddress);
            }
            return JSONValue(values);
        }

        throw new Exception(format("Invalid output type: %s", referenceType));
    }
}

public JSONValue getRuleJSONInputFormat(immutable RuleNode rule) {
    auto structInputType = rule.whenFunction.parameterTypes[0].castOrFail!(immutable StructureType);
    JSONValue[] memberFormats;
    foreach (memberName; structInputType.memberNames) {
        auto memberType = structInputType.getMemberType(memberName);
        memberFormats ~= memberType.getTypeJSONInputFormat(memberName);
    }
    return JSONValue(memberFormats);
}

private JSONValue getTypeJSONInputFormat(immutable Type type, string name) {
    if (auto atomicType = cast(immutable AtomicType) type) {
        string[] acceptedTypes;
        if (atomicType.isBoolean()) {
            acceptedTypes = ["true", "false"];
        } else if (atomicType.isFloat()) {
            acceptedTypes = ["int", "uint", "float"];
        } else if (atomicType.isInteger()) {
            acceptedTypes = [atomicType.isSigned() ? "int" : "uint"];
        } else {
            assert (0);
        }

        JSONValue[string] atomicFormat = [
            "Name": JSONValue(name),
            "Type": JSONValue(acceptedTypes)
        ];
        return JSONValue(atomicFormat);
    }

    if (auto arrayType = cast(immutable ArrayType) type) {
        auto allowString = false;
        if (auto atomicComponentType = cast(immutable AtomicType) arrayType.componentType) {
            allowString = atomicComponentType.isInteger() && !atomicComponentType.isSigned();
        }
        auto acceptedTypes = ["null", "array"] ~ (allowString ? ["string"] : []);

        JSONValue[string] arrayFormat = [
            "Name": JSONValue(name),
            "Type": JSONValue(acceptedTypes),
            "SubObjects": arrayType.componentType.getTypeJSONInputFormat("*")
        ];
        return JSONValue(arrayFormat);
    }

    if (auto structType = cast(immutable StructureType) type) {

        JSONValue[] memberFormats;
        foreach (memberName; structType.memberNames) {
            auto memberType = structType.getMemberType(memberName);
            memberFormats ~= memberType.getTypeJSONInputFormat(memberName);
        }

        JSONValue[string] structFormat = [
            "Name": JSONValue(name),
            "Type": JSONValue(["null", "object"]),
            "SubObjects": JSONValue(memberFormats)
        ];
        return JSONValue(structFormat);
    }

    throw new Exception(format("Invalid input type %s for field %s", type.toString(), name));
}

public Nullable!JSONValue runRule(immutable RuleNode rule, JSONValue jsonInput) {
    // Create and setup the runtime
    auto runtime = new Runtime();
    rule.setupRuntime(runtime);
    // Write the JSON to a struct
    auto inputType = rule.whenFunction.parameterTypes[0].castOrFail!(immutable StructureType);
    void* inputStruct;
    if (!runtime.writeJSONObject(jsonInput, inputType, &inputStruct)) {
        return Nullable!JSONValue();
    }
    // Push the struct on the stach and call the "when" part
    runtime.stack.push(inputStruct);
    runtime.call(rule.whenFunction);
    // Check the results of the "when"
    if (!runtime.stack.pop!bool()) {
        return Nullable!JSONValue();
    }
    // If the condition passes, call the "then" part
    runtime.stack.push(inputStruct);
    runtime.call(rule.thenFunction);
    // Convert the output struct to JSON
    auto thenReturnType = rule.thenFunction.returnType;
    return Nullable!JSONValue(runtime.readJSONValue(thenReturnType, runtime.stack.peekAddress(thenReturnType)));
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

    @property public void* topAddress() {
        return memory + byteIndex;
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

    public void push(T)(immutable Type type, T data) if (!is(T == Variant)) {
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

    public void push(immutable Type type, Variant data) {
        mixin (buildTypeSwitch!"push!($0)(data.get!($0));");
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
