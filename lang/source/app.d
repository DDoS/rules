import core.stdc.stdlib;
import cstdio = core.stdc.stdio;
import core.stdc.signal;

import std.stdio;

import ruleslang.syntax.dcharstream;
import ruleslang.syntax.tokenizer;
import ruleslang.syntax.ast.statement;
import ruleslang.syntax.parser.statement;

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
		stdout.writeln(statement.toString());
    }
}

private extern (C) void sigINT(int sig) @nogc nothrow {
	cstdio.puts("\nbye\0".ptr);
	exit(0);
}
