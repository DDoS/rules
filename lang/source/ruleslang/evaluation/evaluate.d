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
        auto address = runtime.heap.allocateNotScanned(12);
        runtime.stack.push(address);
    }

    public void evaluateSignedIntegerLiteral(Runtime runtime, immutable SignedIntegerLiteralNode signedIntegerLiteral) {
        runtime.stack.push(signedIntegerLiteral.specialType, signedIntegerLiteral.getType().value);
    }

    public void evaluateUnsignedIntegerLiteral(Runtime runtime, immutable UnsignedIntegerLiteralNode unsignedIntegerLiteral) {
        runtime.stack.push(unsignedIntegerLiteral.specialType, unsignedIntegerLiteral.getType().value);
    }

    public void evaluateFloatLiteral(Runtime runtime, immutable FloatLiteralNode floatLiteral) {
        runtime.stack.push(floatLiteral.specialType, floatLiteral.getType().value);
    }

    public void evaluateEmptyLiteral(Runtime runtime, immutable EmptyLiteralNode emptyLiteral) {
        throw new NotImplementedException();
    }

    public void evaluateTupleLiteral(Runtime runtime, immutable TupleLiteralNode tupleLiteral) {
        throw new NotImplementedException();
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

public class NotImplementedException : Exception {
    public this(string func = __FUNCTION__) {
        super(func);
    }
}
