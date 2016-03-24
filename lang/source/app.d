import std.stdio;

import ruleslang.syntax.dcharstream;
import ruleslang.syntax.tokenizer;
import ruleslang.syntax.ast.statement;
import ruleslang.syntax.parser.statement;
import ruleslang.semantic.opexpand;
import ruleslang.semantic.litreduce;

void main() {
	while (true) {
		try {
			stdout.write("> ");
			auto source = stdin.readln();
			if (source.length <= 0) {
				stdout.writeln();
				break;
			}
			auto tokenizer = new Tokenizer(new DCharReader(new StringDCharStream(source)));
		    foreach (statement; tokenizer.parseStatements()) {
				statement = statement.expandOperators();
				statement = statement.reduceLiterals();
				stdout.writeln(statement.toString());
		    }
		} catch (Exception exception) {
			stdout.writeln(exception.msg);
		}
	}
	// TODO: fix unsafe casts
}
