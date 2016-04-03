import std.stdio;

import ruleslang.syntax.source;
import ruleslang.syntax.token;
import ruleslang.syntax.tokenizer;
import ruleslang.syntax.ast.statement;
import ruleslang.syntax.parser.statement;
import ruleslang.semantic.opexpand;
import ruleslang.semantic.tree;
import ruleslang.semantic.interpret;

void main() {
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
				if (assignment) {
					auto node = assignment.value.interpret();
					if (cast(NullNode) node is null) {
						stdout.writeln("RHS semantic: ", node.toString());
					}
					auto typedNode = cast(immutable(TypedNode)) node;
					if (typedNode) {
						stdout.writeln("RHS type: ", typedNode.getType().toString());
					}
				}
		    }
		} catch (SourceException exception) {
			writeln(exception.getErrorInformation(source).toString());
		}
	}
}
