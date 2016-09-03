module ruleslang.evaluation.evaluate;

import ruleslang.semantic.type;
import ruleslang.semantic.tree;
import ruleslang.evaluation.runtime;

public immutable class Evaluator {
    public static immutable Evaluator INSTANCE = new immutable Evaluator();

    private this() {
    }

    public void evaluateBooleanLiteral(Runtime runtime, immutable BooleanLiteralNode booleanLiteral) {
        runtime.stack.push!bool(booleanLiteral.getType().value);
    }

    public void evaluateStringLiteral(Runtime runtime, immutable StringLiteralNode stringLiteral) {
        // Allocate the string
        auto value = stringLiteral.getType().value;
        auto address = runtime.allocateArray(stringLiteral.getTypeIdentity(), value.length);
        // Then place the string data
        auto dataSegment = cast(dchar*) (address + IdentityHeader.sizeof + size_t.sizeof);
        dataSegment[0 .. value.length] = value;
        // Finally push the address to the stack
        runtime.stack.push(address);
    }

    public void evaluateSignedIntegerLiteral(Runtime runtime, immutable SignedIntegerLiteralNode signedIntegerLiteral) {
        runtime.stack.push(signedIntegerLiteral.getType(), signedIntegerLiteral.getType().value);
    }

    public void evaluateUnsignedIntegerLiteral(Runtime runtime, immutable UnsignedIntegerLiteralNode unsignedIntegerLiteral) {
        runtime.stack.push(unsignedIntegerLiteral.getType(), unsignedIntegerLiteral.getType().value);
    }

    public void evaluateFloatLiteral(Runtime runtime, immutable FloatLiteralNode floatLiteral) {
        runtime.stack.push(floatLiteral.getType(), floatLiteral.getType().value);
    }

    public void evaluateEmptyLiteral(Runtime runtime, immutable EmptyLiteralNode emptyLiteral) {
        // Allocate the empty literal
        auto address = runtime.allocateComposite(emptyLiteral.getTypeIdentity());
        // It doesn't have any data, so just push the address to the stack
        runtime.stack.push(address);
    }

    public void evaluateTupleLiteral(Runtime runtime, immutable TupleLiteralNode tupleLiteral) {
        evaluateTupleLiteral(runtime, tupleLiteral.getType(), tupleLiteral.getTypeIdentity(), tupleLiteral.values);
    }

    public void evaluateStructLiteral(Runtime runtime, immutable StructLiteralNode structLiteral) {
        // This is the same as a tuple literal evalution-wise. The member names are just used for access operations
        evaluateTupleLiteral(runtime, structLiteral.getType, structLiteral.getTypeIdentity(), structLiteral.values);
    }

    private static void evaluateTupleLiteral(Runtime runtime, immutable TupleType type, immutable TypeIdentity info,
            immutable(TypedNode)[] values) {
        // Allocate the literal
        auto address = runtime.allocateComposite(info);
        // Place the literal data
        auto dataSegment = address + IdentityHeader.sizeof;
        foreach (i, memberType; type.memberTypes) {
            // Evaluate the member to place the value on the stack
            values[i].evaluate(runtime);
            // Get the member data address
            auto memberAddress = dataSegment + info.memberOffsetByIndex[i];
            // Pop the stack data to the data segment
            runtime.stack.popTo(memberType, memberAddress);
        }
        // Finally push the address to the stack
        runtime.stack.push(address);
    }

    public void evaluateArrayLiteral(Runtime runtime, immutable ArrayLiteralNode arrayLiteral) {
        auto type = arrayLiteral.getType();
        // Allocate the string
        auto identity = arrayLiteral.getTypeIdentity();
        auto length = type.size;
        auto address = runtime.allocateArray(identity, length);
        // Then place the array data
        auto dataSegment = address + IdentityHeader.sizeof + size_t.sizeof;
        foreach (i; 0 .. length) {
            // Get the value for the array index
            auto value = arrayLiteral.getValueAt(i);
            if (value !is null) {
                // Evaluate the data to place the value on the stack
                value.evaluate(runtime);
                // Pop the stack data to the data segment
                runtime.stack.popTo(type.componentType, dataSegment);
            }
            // Increment the data address
            dataSegment += identity.componentSize;
        }
        // Finally push the address to the stack
        runtime.stack.push(address);
    }

    public void evaluateFieldAccess(Runtime runtime, immutable FieldAccessNode fieldAccess) {
        throw new NotImplementedException();
    }

    public void evaluateMemberAccess(Runtime runtime, immutable MemberAccessNode memberAccess) {
        // Evaluate the member access value to place it on the stack
        memberAccess.value.evaluate(runtime);
        // Now get its address from the stack
        auto address = runtime.stack.pop!(void*);
        // Get the type identity from the header
        auto identity = runtime.getTypeIdentity(*(cast(IdentityHeader*) address));
        // From the identity, get the member offset
        auto memberOffset = identity.memberOffsetByName[memberAccess.name];
        // Get the member address
        auto memberAddress = address + IdentityHeader.sizeof + memberOffset;
        // Finally push the member's data onto the stack
        runtime.stack.pushFrom(memberAccess.getType(), memberAddress);
    }

    public void evaluateIndexAccess(Runtime runtime, immutable IndexAccessNode indexAccess) {
        throw new NotImplementedException();
    }

    public void evaluateFunctionCall(Runtime runtime, immutable FunctionCallNode functionCall) {
        // Evaluate the arguments in reverse order to place them on the stack
        foreach_reverse (arg; functionCall.arguments) {
            arg.evaluate(runtime);
        }
        // Then call the function, which will pop the arguments from the stack
        runtime.call(functionCall.func);
    }

    public void evaluateConditional(Runtime runtime, immutable ConditionalNode conditional) {
        // First evaluate the condition node
        conditional.condition.evaluate(runtime);
        // Branch on the value, which is on the top of the stack
        if (runtime.stack.pop!bool()) {
            // Evaluate the true value and leave it on the top of the stack
            conditional.whenTrue.evaluate(runtime);
        } else {
            // Evaluate the false value and leave it on the top of the stack
            conditional.whenFalse.evaluate(runtime);
        }
    }
}

private void* allocateComposite(Runtime runtime, immutable TypeIdentity identity) {
    assert (identity.kind == TypeIdentity.Kind.TUPLE || identity.kind == TypeIdentity.Kind.STRUCT);
    // Register the type identity
    auto infoIndex = runtime.registerTypeIdentity(identity);
    // Calculate the size of the composite (header + data) and allocate the memory
    auto size = IdentityHeader.sizeof + identity.dataSize;
    auto address = runtime.heap.allocateScanned(size);
    // Next set the header
    *(cast (IdentityHeader*) address) = infoIndex;
    return address;
}

private void* allocateArray(Runtime runtime, immutable TypeIdentity identity, size_t length) {
    assert (identity.kind == TypeIdentity.Kind.ARRAY);
    // Register the type identity
    auto infoIndex = runtime.registerTypeIdentity(identity);
    // Calculate the size of the array (header + length field + data) and allocate the memory
    auto size = IdentityHeader.sizeof + size_t.sizeof + identity.componentSize * length;
    // TODO: reference arrays need to be scanned
    auto address = runtime.heap.allocateNotScanned(size);
    // Next set the header
    *(cast (IdentityHeader*) address) = infoIndex;
    // Finally set the length field
    *(cast (size_t*) (address + IdentityHeader.sizeof)) = length;
    return address;
}

public class NotImplementedException : Exception {
    public this(string func = __FUNCTION__) {
        super(func);
    }
}
