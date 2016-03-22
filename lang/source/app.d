import core.stdc.stdlib;
import cstdio = core.stdc.stdio;
import core.stdc.signal;

import std.stdio;

import ruleslang.syntax.dcharstream;
import ruleslang.syntax.tokenizer;
import ruleslang.syntax.ast.statement;
import ruleslang.syntax.parser.statement;
import ruleslang.semantic.litreduce;

void main() {
	signal(SIGINT, &sigINT);

	while (true) {
		try {
			parseLine();
		} catch (Exception exception) {
			stdout.writeln(exception.msg);
		}
	}
}

private void parseLine() {
	stdout.write("> ");
    auto tokenizer = new Tokenizer(new DCharReader(new ReadLineDCharStream(stdin)));
    foreach (statement; tokenizer.parseStatements()) {
		statement = statement.reduceLiterals();
		stdout.writeln(statement.toString());
    }
}

private extern (C) void sigINT(int sig) @nogc nothrow {
	cstdio.puts("\nbye".ptr);
	exit(0);
}
