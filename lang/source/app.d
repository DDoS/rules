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
    auto atomicType = cast(immutable AtomicType) type;
    if (atomicType !is null) {
        return stack.pop(atomicType).toString();
    }
    auto compositeType = cast(immutable CompositeType) type;
    if (compositeType !is null) {
        return stack.pop!size_t().to!string;
    }
    assert (0);
}
