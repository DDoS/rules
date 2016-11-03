module ruleslang.test.parser.rule;

import std.stdio : stderr;

import ruleslang.syntax.source;
import ruleslang.syntax.token;
import ruleslang.syntax.tokenizer;
import ruleslang.syntax.parser.rule;

import ruleslang.test.assertion;

unittest {
    assertEqual(
        "Rule(WhenDefinition(when (Something data): ReturnStatement(return Compare(data.m == SignedIntegerLiteral(0)))))",
        parse("when (Something data):\n return data.m == 0")
    );
    assertEqual(
        "Rule(ThenDefinition(then (Stuff[SignedIntegerLiteral(2)] data): "
            ~ "ReturnStatement(return IndexAccess(data[SignedIntegerLiteral(1)]))))",
        parse("then (Stuff[2] data):\n return data[1]")
    );
}

private string parse(string source) {
    try {
        auto rule = new Tokenizer(new DCharReader(source)).parseRule();
        return rule.toString();
    } catch (SourceException exception) {
        stderr.writeln(exception.getErrorInformation(source).toString());
        assert (0);
    }
}
