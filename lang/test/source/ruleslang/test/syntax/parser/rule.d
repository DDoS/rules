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
    assertEqual(
        "Rule(WhenDefinition(when (S d): ReturnStatement(return BooleanLiteral(true))); "
            ~ "ThenDefinition(then (S d): FunctionCall(a())))",
        parse("when (S d):\n return true\nthen(S d):\n a()")
    );
    assertEqual(
        "Rule(TypeDefinition(def S: {int a}); VariableDeclaration(let b = BooleanLiteral(true)); "
            ~ "FunctionDefinition(func a(): FunctionCall(exit(Sign(-SignedIntegerLiteral(1))))); "
            ~ "WhenDefinition(when (S d): ReturnStatement(return b)); ThenDefinition(then (S d): FunctionCall(a())))",
        parse("def S: {int a}\nlet b = true\nwhen (S d):\n return b\nthen(S d):\n a()\nfunc a():\n exit(-1)")
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
