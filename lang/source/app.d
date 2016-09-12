import std.stdio;
import std.conv : to;

import ruleslang.syntax.source;
import ruleslang.syntax.token;
import ruleslang.syntax.tokenizer;
import ruleslang.syntax.ast.statement;
import ruleslang.syntax.ast.expression;
import ruleslang.syntax.parser.statement;
import ruleslang.semantic.opexpand;
import ruleslang.semantic.type;
import ruleslang.semantic.tree;
import ruleslang.semantic.context;
import ruleslang.semantic.interpret;
import ruleslang.evaluation.runtime;
import ruleslang.evaluation.evaluate;

void main() {
    /*
        TODO:
            Interpret type declarations
            Interpret initializers
            Interpret type compares
            Parse variable declarations
            Interpret variable declarations
            Interpret assignments
            Parse control flow
            Interpret control flow
    */
    auto context = new Context();
    auto runtime = new IntrinsicRuntime();
    while (true) {
        stdout.write("> ");
        auto source = stdin.readln();
        if (source.length <= 0) {
            stdout.writeln();
            break;
        }
        try {
            auto tokenizer = new Tokenizer(new DCharReader(source));
            foreach (statement; tokenizer.parseStatements()) {
                statement = statement.expandOperators();
                stdout.writeln(statement.toString());
                auto assignment = cast(Assignment) statement;
                if (assignment !is null) {
                    assignment.value.printInfo(context, runtime);
                    continue;
                }
                auto functionCall = cast(FunctionCall) statement;
                if (functionCall !is null) {
                    functionCall.printInfo(context, runtime);
                    continue;
                }
            }
        } catch (SourceException exception) {
            writeln(exception.getErrorInformation(source).toString());
        }
    }
}

private void printInfo(Expression expression, Context context, Runtime runtime) {
    auto node = expression.interpret(context);
    if (cast(NullNode) node !is null) {
        return;
    }
    stdout.writeln("RHS semantic: ", node.toString());
    auto typedNode = cast(immutable TypedNode) node;
    if (typedNode is null) {
        return;
    }
    auto reducedNode = typedNode.reduceLiterals();
    auto type = reducedNode.getType();
    stdout.writeln("RHS type: ", type.toString());
    try {
        reducedNode.evaluate(runtime);
        stdout.writeln("RHS value: ", runtime.getStackTop(type));
    } catch (NotImplementedException ignored) {
        stdout.writeln("RHS value not implemented: ", ignored.msg);
    }
}

private string getStackTop(Runtime runtime, immutable Type type) {
    return runtime.asString(type, runtime.stack.peekAddress(type));
}

private string asString(Runtime runtime, immutable Type type, void* address) {
    auto atomicType = cast(immutable AtomicType) type;
    if (atomicType !is null) {
        return atomicType.asString(address);
    }

    auto referenceAddress = *(cast(void**) address);
    if (referenceAddress is null) {
        return "null";
    }

    auto referenceType = runtime.getType(*(cast(TypeIndex*) referenceAddress));
    auto dataLayout = referenceType.getDataLayout();
    auto dataSegment = referenceAddress + TypeIndex.sizeof;

    auto stringLiteral = cast(immutable StringLiteralType) referenceType;
    if (stringLiteral !is null) {
        auto length = *(cast(size_t*) dataSegment);
        dataSegment += size_t.sizeof;
        dchar[] stringData = (cast(dchar*) dataSegment)[0 .. length];
        return '"' ~ stringData.idup.to!string() ~ '"';
    }

    auto arrayType = cast(immutable ArrayType) referenceType;
    if (arrayType !is null) {
        auto length = *(cast(size_t*) dataSegment);
        dataSegment += size_t.sizeof;
        string str = "{";
        foreach (i; 0 .. length) {
            str ~= runtime.asString(arrayType.componentType, dataSegment);
            dataSegment += dataLayout.componentSize;
            if (i < length - 1) {
                str ~= ", ";
            }
        }
        str ~= "}";
        return str;
    }

    auto anyType = cast(immutable AnyType) referenceType;
    if (anyType !is null) {
        return "{}";
    }

    auto structType = cast(immutable StructureType) referenceType;
    if (structType !is null) {
        string str = "{";
        foreach (i, memberName; structType.memberNames) {
            auto memberType = structType.getMemberType(i);
            str ~= memberName ~ ": ";
            str ~= runtime.asString(memberType, dataSegment + dataLayout.memberOffsetByName[memberName]);
            if (i < structType.memberNames.length - 1) {
                str ~= ", ";
            }
        }
        str ~= "}";
        return str;
    }

    auto tupleType = cast(immutable TupleType) referenceType;
    if (tupleType !is null) {
        string str = "{";
        foreach (i, memberType; tupleType.memberTypes) {
            str ~= runtime.asString(memberType, dataSegment + dataLayout.memberOffsetByIndex[i]);
            if (i < tupleType.memberTypes.length - 1) {
                str ~= ", ";
            }
        }
        str ~= "}";
        return str;
    }

    assert (0);
}

private string asString(immutable AtomicType type, void* address) {
    if (AtomicType.BOOL.opEquals(type)) {
        return (*(cast(bool*) address)).to!string();
    }
    if (AtomicType.SINT8.opEquals(type)) {
        return (*(cast(byte*) address)).to!string();
    }
    if (AtomicType.UINT8.opEquals(type)) {
        return (*(cast(ubyte*) address)).to!string();
    }
    if (AtomicType.SINT16.opEquals(type)) {
        return (*(cast(short*) address)).to!string();
    }
    if (AtomicType.UINT16.opEquals(type)) {
        return (*(cast(ushort*) address)).to!string();
    }
    if (AtomicType.SINT32.opEquals(type)) {
        return (*(cast(int*) address)).to!string();
    }
    if (AtomicType.UINT32.opEquals(type)) {
        return (*(cast(uint*) address)).to!string();
    }
    if (AtomicType.SINT64.opEquals(type)) {
        return (*(cast(long*) address)).to!string();
    }
    if (AtomicType.UINT64.opEquals(type)) {
        return (*(cast(ulong*) address)).to!string();
    }
    if (AtomicType.FP32.opEquals(type)) {
        return (*(cast(float*) address)).to!string();
    }
    if (AtomicType.FP64.opEquals(type)) {
        return (*(cast(double*) address)).to!string();
    }
    assert (0);
}
