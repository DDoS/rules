import std.stdio;

import ruleslang.syntax.dcharstream;
import ruleslang.syntax.token;
import ruleslang.syntax.tokenizer;
import ruleslang.syntax.ast.statement;
import ruleslang.syntax.parser.statement;
import ruleslang.semantic.opexpand;
import ruleslang.semantic.litreduce;

void main() {
	while (true) {
		stdout.write("> ");
		auto source = stdin.readln();
		if (source.length <= 0) {
			stdout.writeln();
			break;
		}
		try {
			auto tokenizer = new Tokenizer(new DCharReader(new StringDCharStream(source)));
		    foreach (statement; tokenizer.parseStatements()) {
				statement = statement.expandOperators();
				statement = statement.reduceLiterals();
				stdout.writeln(statement.toString());
		    }
		} catch (SourceException exception) {
			writeln(exception.getErrorInformation(source).toString());
		}
	}
	// TODO: fix unsafe casts
	//       Remove char stream stuff, just keep reader
}
