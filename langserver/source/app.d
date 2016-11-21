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

shared static RuleNode[string] rulesSets;

shared static this()
{
	auto router = new URLRouter;
	router
		.post("/rules/:ruleset", &newRuleSet)
		.put("/rules/:ruleset", &interpret);		

	auto settings = new HTTPServerSettings;
	settings.port = 8080;
	settings.bindAddresses = ["::1", "127.0.0.1"];

	listenHTTP(settings, router);

	logInfo("Please open http://127.0.0.1:8080/ in your browser.");
}

void newRuleSet(HTTPServerRequest req, HTTPServerResponse res)
{
	writeln("New RuleSet: "~req.params["ruleset"]);
	
	auto ruleName = req.params["ruleset"];
	auto source = req.json["rules"].get!string;
    auto context = new Context();
    auto ruleNode = new Tokenizer(new DCharReader(source)).parseRule().expandOperators().interpret(context);
	
	writeln("Saving Rules... "~req.params["ruleset"]);
	rulesSets[ruleName] = cast(shared RuleNode)ruleNode;	
	writeln("Saved Rules... "~req.params["ruleset"]);
}

void interpret(HTTPServerRequest req, HTTPServerResponse res)
{
	writeln("Interpret: "~req.params["ruleset"]);
	
	auto ruleName = req.params["ruleset"];
	auto ruleSet = cast(immutable RuleNode)rulesSets[ruleName];
	auto input = req.json["input"].get!string;
	auto jsonInput = parseJSON(input);
    auto jsonOutput = ruleSet.runRule(jsonInput);
    
	if (jsonOutput.isNull) {
        writeln("Rule not applicable");
    } else {
		auto output = jsonOutput.get();
		res.writeBody(output.toString(),"application/json; charset=UTF-8");
    }
}