module ruleslang.evaluation.evaluate;

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
        auto address = runtime.allocate(stringLiteral);
        // Then place the string data
        auto dataSegment = cast(dchar*) (address + CompositeHeader.sizeof);
        foreach (dchar c; stringLiteral.getType().value) {
            *dataSegment = c;
            dataSegment += 1;
        }
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
        auto address = runtime.allocate(emptyLiteral);
        // It doesn't have any data, so just push the address to the stack
        runtime.stack.push(address);
    }

    public void evaluateTupleLiteral(Runtime runtime, immutable TupleLiteralNode tupleLiteral) {
        // Allocate the composite
        auto address = runtime.allocate(tupleLiteral);
        // Then evaluate the members to place the data on the stack
        auto dataSegment = address + CompositeHeader.sizeof;
        foreach (i, memberType; tupleLiteral.getType().memberTypes) {
            auto memberNode = tupleLiteral.values[i];
            memberNode.evaluate(runtime);
            // Pop the stack data to the data segment, which also increments the location
            runtime.stack.popTo(memberType, dataSegment);
        }
        // Finally push the address to the stack
        runtime.stack.push(address);
    }

    public void evaluateStructLiteral(Runtime runtime, immutable StructLiteralNode structLiteral) {
        throw new NotImplementedException();
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

private void* allocate(Runtime runtime, immutable CompositeNode node) {
    // Grab and register the composite info
    auto info = node.getCompositeInfo();
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
