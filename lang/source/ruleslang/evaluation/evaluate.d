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
    }

    public void evaluateTupleLiteral(Runtime runtime, immutable TupleLiteralNode tupleLiteral) {
    }

    public void evaluateStructLiteral(Runtime runtime, immutable StructLiteralNode structLiteral) {
    }

    public void evaluateArrayLiteral(Runtime runtime, immutable ArrayLiteralNode arrayLiteral) {
    }

    public void evaluateFieldAccess(Runtime runtime, immutable FieldAccessNode fieldAccess) {
    }

    public void evaluateMemberAccess(Runtime runtime, immutable MemberAccessNode memberAccess) {
    }

    public void evaluateIndexAccess(Runtime runtime, immutable IndexAccessNode indexAccess) {
    }

    public void evaluateFunctionCall(Runtime runtime, immutable FunctionCallNode functionCall) {
    }
}
