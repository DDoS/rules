module ruleslang.evaluation.evaluate;

import std.format : format;
import std.variant : Variant;

import ruleslang.syntax.source;
import ruleslang.semantic.type;
import ruleslang.semantic.tree;
import ruleslang.evaluation.runtime;

public immutable class Evaluator {
    public static immutable Evaluator INSTANCE = new immutable Evaluator();

    private this() {
    }

    public void evaluateNullLiteral(Runtime runtime, immutable NullLiteralNode nullLiteral) {
        runtime.stack.push!(void*)(null);
    }

    public void evaluateBooleanLiteral(Runtime runtime, immutable BooleanLiteralNode booleanLiteral) {
        runtime.stack.push!bool(booleanLiteral.getType().value);
    }

    public void evaluateStringLiteral(Runtime runtime, immutable StringLiteralNode stringLiteral) {
        // Allocate the string
        auto value = stringLiteral.getType().value;
        auto address = runtime.allocateArray(stringLiteral.getType(), value.length);
        // Then place the string data
        auto dataSegment = cast(dchar*) (address + TypeIndex.sizeof + size_t.sizeof);
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
        auto address = runtime.allocateComposite(emptyLiteral.getType());
        // It doesn't have any data, so just push the address to the stack
        runtime.stack.push(address);
    }

    public void evaluateTupleLiteral(Runtime runtime, immutable TupleLiteralNode tupleLiteral) {
        evaluateTupleLiteral(runtime, tupleLiteral.getType(), tupleLiteral.values);
    }

    public void evaluateStructLiteral(Runtime runtime, immutable StructLiteralNode structLiteral) {
        // This is the same as a tuple literal evalution-wise. The member names are just used for access operations
        evaluateTupleLiteral(runtime, structLiteral.getType(), structLiteral.values);
    }

    private static void evaluateTupleLiteral(Runtime runtime, immutable TupleType type, immutable(TypedNode)[] values) {
        // Allocate the literal
        auto address = runtime.allocateComposite(type);
        // Place the literal data
        auto dataLayout = type.getDataLayout();
        auto dataSegment = address + TypeIndex.sizeof;
        foreach (i, memberType; type.memberTypes) {
            // Evaluate the member to place the value on the stack
            values[i].evaluate(runtime);
            // Get the member data address
            auto memberAddress = dataSegment + dataLayout.memberOffsetByIndex[i];
            // Pop the stack data to the data segment
            runtime.stack.popTo(memberType, memberAddress);
        }
        // Finally push the address to the stack
        runtime.stack.push(address);
    }

    public void evaluateArrayLiteral(Runtime runtime, immutable ArrayLiteralNode arrayLiteral) {
        auto type = arrayLiteral.getType();
        // Allocate the string
        auto length = type.size;
        auto address = runtime.allocateArray(type, length);
        // Then place the array data
        auto dataLayout = type.getDataLayout();
        auto dataSegment = address + TypeIndex.sizeof + size_t.sizeof;
        bool foundOther = false;
        Variant otherCache;
        for (size_t i = 0; i < length; i += 1, dataSegment += dataLayout.componentSize) {
            // Get the value for the array index
            bool isOther;
            auto value = arrayLiteral.getValueAt(i, isOther);
            if (value is null) {
                continue;
            }
            // If the value has the "other" label then we must only evaluate it a single time
            if (isOther && foundOther) {
                otherCache.writeVariant(dataSegment);
                continue;
            }
            // Evaluate the data to place the value on the stack
            value.evaluate(runtime);
            if (isOther && !foundOther) {
                // If it is the first labeled with "other" cache it for reuse
                otherCache = runtime.stack.peek(type.componentType);
                foundOther = true;
            }
            // Pop the stack data to the data segment
            runtime.stack.popTo(type.componentType, dataSegment);
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
        // Now get its address from the stack and do a null check
        auto address = runtime.stack.pop!(void*);
        if (address is null) {
            throw new SourceException("Null reference", memberAccess.value);
        }
        // Get the type from the header
        auto type = runtime.getType(*(cast(TypeIndex*) address));
        // From the type data layout, get the member offset
        auto memberOffset = type.getDataLayout().memberOffsetByName[memberAccess.name];
        // Get the member address
        auto memberAddress = address + TypeIndex.sizeof + memberOffset;
        // Finally push the member's data onto the stack
        runtime.stack.pushFrom(memberAccess.getType(), memberAddress);
    }

    public void evaluateIndexAccess(Runtime runtime, immutable IndexAccessNode indexAccess) {
        // Evaluate the index access value to place it on the stack
        indexAccess.value.evaluate(runtime);
        // Now get its address from the stack and do a null check
        auto address = runtime.stack.pop!(void*);
        if (address is null) {
            throw new SourceException("Null reference", indexAccess.value);
        }
        // Now do the same for the index value
        indexAccess.index.evaluate(runtime);
        auto index = runtime.stack.pop!ulong();
        // Get the type and data layout from the header
        auto type = runtime.getType(*(cast(TypeIndex*) address));
        auto dataLayout = type.getDataLayout();
        // Get the data segment
        auto dataSegment = address + TypeIndex.sizeof;
        // Getting the member offset needs to be handled differently according to the kind
        size_t memberOffset;
        final switch (dataLayout.kind) with (DataLayout.Kind) {
            case TUPLE: {
                // From the data layout, get the member offset from the index
                memberOffset = dataLayout.memberOffsetByIndex[index];
                break;
            }
            case STRUCT: {
                auto valueType = indexAccess.value.getType();
                // Accessing for a tuple or struct type works differently
                auto tupleType = cast(immutable TupleType) valueType;
                if (tupleType !is null) {
                    // From the data layout, get the member offset from the index
                    memberOffset = dataLayout.memberOffsetByIndex[index];
                    break;
                }
                // Since struct members can be reorderd by reference widening, we need to use the name
                auto structType = cast(immutable StructureType) valueType;
                if (structType !is null) {
                    // From the type, get the name at the index
                    auto memberName = structType.memberNames[index];
                    // From the data layout, get the member offset from the name
                    memberOffset = dataLayout.memberOffsetByName[memberName];
                    break;
                }
                assert (0);
            }
            case ARRAY: {
                // First do a bounds check
                auto length = *(cast(size_t*) dataSegment);
                if (index >= length) {
                    throw new SourceException(format("Index %d is out of bounds of [0 .. %d]", index, length),
                            indexAccess.index);
                }
                // Calculate the offset as the length field size plus the component size times the index
                memberOffset = size_t.sizeof + dataLayout.componentSize * index;
                break;
            }
        }
        // Get the member address
        auto memberAddress = dataSegment + memberOffset;
        // Finally push the member's data onto the stack
        runtime.stack.pushFrom(indexAccess.getType(), memberAddress);
    }

    public void evaluateFunctionCall(Runtime runtime, immutable FunctionCallNode functionCall) {
        // Evaluate the arguments in reverse order to place them on the stack
        foreach_reverse (arg; functionCall.arguments) {
            arg.evaluate(runtime);
        }
        // Then call the function, which will pop the arguments from the stack
        runtime.call(functionCall.func);
    }

    public void evaluateReferenceCompare(Runtime runtime, immutable ReferenceCompareNode referenceCompare) {
        // Evaluate the left operand and get the address
        referenceCompare.left.evaluate(runtime);
        auto addressA = runtime.stack.pop!(void*);
        // Evaluate the right operand and get the address
        referenceCompare.right.evaluate(runtime);
        auto addressB = runtime.stack.pop!(void*);
        // Use the equivalent Dlang operator to evaluate
        bool equal;
        if (referenceCompare.negated) {
            equal = addressA !is addressB;
        } else {
            equal = addressA is addressB;
        }
        // Push the result onto the stack
        runtime.stack.push!bool(equal);
    }

    public void evaluateTypeCompare(Runtime runtime, immutable TypeCompareNode typeCompare) {
        // Evaluate the value operand and get the address
        typeCompare.value.evaluate(runtime);
        auto address = runtime.stack.pop!(void*);
        // From the address get the type
        auto type = runtime.getType(*(cast(TypeIndex*) address));
        // Perform the comparison according to the kind
        auto compareType = typeCompare.compareType;
        bool result;
        final switch (typeCompare.kind) with (TypeCompareNode.Kind) {
            case EQUAL:
                result = type.opEquals(compareType);
                break;
            case NOT_EQUAL:
                result = !type.opEquals(compareType);
                break;
            case SUBTYPE:
                auto conversions = new TypeConversionChain();
                result = type.convertibleTo(compareType, conversions);
                break;
            case SUPERTYPE:
                auto conversions = new TypeConversionChain();
                result = compareType.convertibleTo(type, conversions);
                break;
            case PROPER_SUBTYPE:
                auto conversions = new TypeConversionChain();
                result = type.convertibleTo(compareType, conversions) && !compareType.convertibleTo(type, conversions);
                break;
            case PROPER_SUPERTYPE:
                auto conversions = new TypeConversionChain();
                result = !type.convertibleTo(compareType, conversions) && compareType.convertibleTo(type, conversions);
                break;
            case DISTINCT:
                auto conversions = new TypeConversionChain();
                result = !type.convertibleTo(compareType, conversions) && !compareType.convertibleTo(type, conversions);
                break;
        }
        // Push the result onto the stack
        runtime.stack.push!bool(result);
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

public class NotImplementedException : Exception {
    public this(string func = __FUNCTION__) {
        super(func);
    }
}
