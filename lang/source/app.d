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
    auto context = new Context();
    auto runtime = new Runtime();
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
    if (cast(NullNode) node is null) {
        stdout.writeln("RHS semantic: ", node.toString());
    }
    auto typedNode = cast(immutable(TypedNode)) node;
    if (typedNode !is null) {
        auto type = typedNode.getType();
        stdout.writeln("RHS type: ", type.toString());
        typedNode.evaluate(runtime);
        if (!runtime.stack.isEmpty()) {
            stdout.writeln("RHS value: ", runtime.stack.getTop(type));
        }
    }
}

private string getTop(Stack stack, immutable Type type) {
    auto literalType = cast(immutable LiteralType) type;
    if (literalType !is null) {
        return getTop(stack, literalType.getBackingType());
    }
    if (type == AtomicType.BOOL) {
        return stack.pop!bool().to!string;
    }
    if (type == AtomicType.SINT8) {
        return stack.pop!byte().to!string;
    }
    if (type == AtomicType.UINT8) {
        return stack.pop!ubyte().to!string;
    }
    if (type == AtomicType.SINT16) {
        return stack.pop!short().to!string;
    }
    if (type == AtomicType.UINT16) {
        return stack.pop!ushort().to!string;
    }
    if (type == AtomicType.SINT32) {
        return stack.pop!int().to!string;
    }
    if (type == AtomicType.UINT32) {
        return stack.pop!uint().to!string;
    }
    if (type == AtomicType.SINT64) {
        return stack.pop!long().to!string;
    }
    if (type == AtomicType.UINT64) {
        return stack.pop!ulong().to!string;
    }
    if (type == AtomicType.FP32) {
        return stack.pop!float().to!string;
    }
    if (type == AtomicType.FP64) {
        return stack.pop!double().to!string;
    }
    auto compositeType = cast(CompositeType) type;
    if (compositeType !is null) {
        return stack.pop!size_t().to!string;
    }
    assert (0);
}
