import std.stdio;
import std.conv : to;

import ruleslang.syntax.dchars;
import ruleslang.syntax.source;
import ruleslang.syntax.token;
import ruleslang.syntax.tokenizer;
import ruleslang.syntax.ast.expression;
import ruleslang.syntax.ast.statement;
import ruleslang.syntax.parser.expression;
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
            Function definition evaluation
            Add break and continue statements to loops
    */
    auto context = new Context(BlockKind.SHELL);
    auto runtime = new IntrinsicRuntime();
    bool expressionMode = false;
    while (true) {
        auto source = readSource(expressionMode);
        if (source.length <= 0) {
            stdout.writeln();
            break;
        }
        if (source[0] == '\u0001') {
            expressionMode ^= true;
            continue;
        }
        try {
            source = "func test9() bool:\n var a = true\n if true:\n  a = false\n else:\n  a = true\n if true:\n  a = true\n else:\n  a = false\n return a";
            //source = "func test9() bool:\n var a = true\n if true:\n  a = false\n else:\n  a = true\n a ^^= false\n return a";
            //source = "func test9() bool:\n var bool b\n if true:\n  b = false\n else:\n  b = true\n if true:\n  if false:\n   let a = 1\n return b";
            //source = "func test9() bool:\n if true:\n  ;\n else:\n  return true\n return false";
            //source = "func test9() bool:\n var d = -1\n if false:\n  d = 0\n else if true:\n  d = 1\n else:\n  d = 2\n";
            //source = "func test9() bool:\n var d = -1\n if false:\n  return true\n else if true:\n  d = 1\n else:\n  d = 2\n";
            //source = "func test9() bool:\n if true:\n  return false\n else:\n  return true\n return !false";
            //source = "func test9() bool:\n if true:\n  return false\n else:\n  return true";
            auto tokenizer = new Tokenizer(new DCharReader(source));
            if (expressionMode) {
                while (tokenizer.head().getKind() == Kind.INDENTATION) {
                    tokenizer.advance();
                }
                if (tokenizer.head().getKind() != Kind.EOF) {
                    auto expression = tokenizer.parseExpression();
                    auto lastKind = tokenizer.head().getKind();
                    if (lastKind != Kind.EOF && lastKind != Kind.INDENTATION) {
                        throw new SourceException("Expected end of expression", tokenizer.head());
                    }
                    expression.evaluate(context, runtime);
                }
            } else {
                foreach (statement; tokenizer.parseStatements()) {
                    statement.evaluate(context, runtime);
                }
            }
            stdout.writeln("stack size: ", runtime.stack.usedSize, "B");
        } catch (SourceException exception) {
            writeln(exception.getErrorInformation(source).toString());
        }
    }
}

private string readSource(bool expressionMode) {
    if (expressionMode) {
        stdout.write(">>");
    }
    stdout.write("> ");
    auto source = stdin.readln();
    while (!expressionMode && source.endsWithIgnoreWhiteSpace(':')) {
        string nextLine;
        do {
            stdout.write("> ");
            nextLine = stdin.readln();
            source ~= nextLine;
        } while (nextLine.length > 0 && nextLine[0].isLineWhiteSpace());
    }
    return source;
}

private bool endsWithIgnoreWhiteSpace(string s, char c) {
    foreach_reverse (cs; s) {
        if (!cs.isWhiteSpace()) {
            if (cs == c) {
                return true;
            }
            break;
        }
    }
    return false;
}

private void evaluate(Expression expression, Context context, Runtime runtime) {
    stdout.writeln("syntax: ", expression.toString());
    auto node = expression.expandOperators().interpret(context);
    if (cast(NullNode) node !is null) {
        return;
    }
    stdout.writeln("semantic: ", node.toString());
    auto reducedNode = node.reduceLiterals();
    auto type = reducedNode.getType();
    stdout.writeln("type: ", type.toString());
    try {
        reducedNode.evaluate(runtime);
        auto valueAddress = runtime.stack.peekAddress(type);
        stdout.writeln("value: ", runtime.asString(type, valueAddress));
        runtime.stack.pop(type);
    } catch (NotImplementedException ignored) {
        stdout.writeln("value not implemented: ", ignored.msg);
    }
}

private void evaluate(Statement statement, Context context, Runtime runtime) {
    stdout.writeln("syntax: ", statement.toString());
    auto node = statement.expandOperators().interpret(context);
    if (cast(NullNode) node !is null) {
        return;
    }
    stdout.writeln("semantic: ", node.toString());
    try {
        Flow flow;
        do {
            flow = node.evaluate(runtime);
        } while (flow.action == Flow.Action.RERUN);
    } catch (NotImplementedException ignored) {
        stdout.writeln("value not implemented: ", ignored.msg);
    }
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
        string value;
        final switch (stringLiteral.encoding) with (StringLiteralType.Encoding) {
            case UTF8:
                value = (cast(char*) dataSegment)[0 .. length].idup;
                break;
            case UTF16:
                value = (cast(wchar*) dataSegment)[0 .. length].idup.to!string();
                break;
            case UTF32:
                value = (cast(dchar*) dataSegment)[0 .. length].idup.to!string();
                break;
        }
        return '"' ~ value ~ '"';
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
