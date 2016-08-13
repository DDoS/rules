import std.stdio;

import ruleslang.syntax.source;
import ruleslang.syntax.token;
import ruleslang.syntax.tokenizer;
import ruleslang.syntax.ast.statement;
import ruleslang.syntax.ast.expression;
import ruleslang.syntax.parser.statement;
import ruleslang.semantic.opexpand;
import ruleslang.semantic.tree;
import ruleslang.semantic.context;
import ruleslang.semantic.interpret;

void main() {
	auto context = new Context();
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
					assignment.value.interpret(context).printSemantic();
				} else {
					auto functionCall = cast(FunctionCall) statement;
					if (functionCall !is null) {
						functionCall.interpret(context).printSemantic();
					}
				}
		    }
		} catch (SourceException exception) {
			writeln(exception.getErrorInformation(source).toString());
		}
	}
}

private void printSemantic(immutable(Node) node) {
	if (cast(NullNode) node is null) {
		stdout.writeln("RHS semantic: ", node.toString());
	}
	auto typedNode = cast(immutable(TypedNode)) node;
	if (typedNode) {
		stdout.writeln("RHS type: ", typedNode.getType().toString());
	}
}
