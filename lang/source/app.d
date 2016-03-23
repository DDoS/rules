import std.stdio;

import ruleslang.syntax.dcharstream;
import ruleslang.syntax.tokenizer;
import ruleslang.syntax.ast.statement;
import ruleslang.syntax.parser.statement;
import ruleslang.semantic.litreduce;

void main() {
	bool open = true;
	while (open) {
		try {
			open = parseLine();
		} catch (Exception exception) {
			stdout.writeln(exception.msg);
		}
	}
}

private bool parseLine() {
	stdout.write("> ");
	auto stream = new ReadLineDCharStream(stdin);
	if (stream.isClosed()) {
		stdout.writeln();
		return false;
	}
    auto tokenizer = new Tokenizer(new DCharReader(stream));
    foreach (statement; tokenizer.parseStatements()) {
		statement = statement.reduceLiterals();
		stdout.writeln(statement.toString());
    }
	return true;
}
