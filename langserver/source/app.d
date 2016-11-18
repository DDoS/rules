import vibe.d;
import std.stdio;
import std.json;

import ruleslang.syntax.dchars;
import ruleslang.syntax.tokenizer;
import ruleslang.semantic.context;

/* 	Remove this once I find out which ones are specifically needed */
import ruleslang.syntax.source;
import ruleslang.syntax.token;
import ruleslang.syntax.ast.expression;
import ruleslang.syntax.ast.statement;
import ruleslang.syntax.parser.expression;
import ruleslang.syntax.parser.statement;
import ruleslang.syntax.parser.rule;
import ruleslang.semantic.opexpand;
import ruleslang.semantic.type;
import ruleslang.semantic.tree;
import ruleslang.semantic.interpret;
import ruleslang.evaluation.runtime;
import ruleslang.evaluation.evaluate;
import ruleslang.util;

shared static this()
{
	auto router = new URLRouter;
	router.post("/interpret", &interpret);

	auto settings = new HTTPServerSettings;
	settings.port = 8080;
	settings.bindAddresses = ["::1", "127.0.0.1"];

	listenHTTP(settings, router);

	logInfo("Please open http://127.0.0.1:8080/ in your browser.");
}

void interpret(HTTPServerRequest req, HTTPServerResponse res)
{
	auto input = req.json["input"].get!string;
	auto rules = req.json["rules"].get!string;
	
    auto jsonInput = parseJSON(input);
    auto source = rules;

    auto context = new Context();
    auto ruleNode = new Tokenizer(new DCharReader(source)).parseRule().expandOperators().interpret(context);
    auto jsonOutput = ruleNode.runRule(jsonInput);
    if (jsonOutput.isNull) {
        writeln("Rule not applicable");
    } else {
		auto output = jsonOutput.get();
		res.writeJsonBody(output.toString);
    }
}

/*

TEST OBJECT

{
	"input":"{\"anInt\": {\"i\": 2}, \"aFloat\": {\"f\": 7.5}}",
	"rules":"def Numbers: {AnInt anInt, AFloat aFloat}\n\ndef AnInt: {sint64 i}\ndef AFloat: {fp32 f}\n\nwhen (Numbers numbers):\n    return numbers.anInt.i != numbers.aFloat.f;\n\nthen (Numbers numbers):\n    return {anInt: {i: numbers.anInt.i + sint64(numbers.aFloat.f)}, aFloat: numbers.aFloat}"
}

*/
