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
        auto address = runtime.allocate(stringLiteral.getCompositeInfo());
        // Then place the string data
        auto dataSegment = cast(dchar*) (address + CompositeHeader.sizeof);
        auto value = stringLiteral.getType().value;
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
        // Allocate the empty composite
        auto address = runtime.allocate(emptyLiteral.getCompositeInfo());
        // It doesn't have any data, so just push the address to the stack
        runtime.stack.push(address);
    }

    public void evaluateTupleLiteral(Runtime runtime, immutable TupleLiteralNode tupleLiteral) {
        evaluateTupleLiteral(runtime, tupleLiteral.getType(), tupleLiteral.getCompositeInfo(), tupleLiteral.values);
    }

    public void evaluateStructLiteral(Runtime runtime, immutable StructLiteralNode structLiteral) {
        // This is the same as a tuple literal evalution-wise. The member names are just used for access operations
        evaluateTupleLiteral(runtime, structLiteral.getType, structLiteral.getCompositeInfo(), structLiteral.values);
    }

    private static void evaluateTupleLiteral(Runtime runtime, immutable TupleType type, immutable CompositeInfo info,
            immutable(TypedNode)[] values) {
        // Allocate the composite
        auto address = runtime.allocate(info);
        // Place the composite data
        auto dataSegment = address + CompositeHeader.sizeof;
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
        throw new NotImplementedException();
    }

    public void evaluateFieldAccess(Runtime runtime, immutable FieldAccessNode fieldAccess) {
        throw new NotImplementedException();
    }

    public void evaluateMemberAccess(Runtime runtime, immutable MemberAccessNode memberAccess) {
        throw new NotImplementedException();
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
}

private void* allocate(Runtime runtime, immutable CompositeInfo info) {
    // Register the composite info
    auto infoIndex = runtime.registerCompositeInfo(info);
    // Calculate the size of the string (header + data) and allocate the memory
    auto size = CompositeHeader.sizeof + info.dataSize;
    auto address = runtime.heap.allocateNotScanned(size);
    // Next set the header
    *(cast (CompositeHeader*) address) = infoIndex;
    return address;
}

public class NotImplementedException : Exception {
    public this(string func = __FUNCTION__) {
        super(func);
    }
}
