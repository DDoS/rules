import vibe.d;
import std.stdio;
import std.json;
import std.typecons : Rebindable;

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
/*
interface IRuleProvider
{
	@path("/api/v1/rules/:name") @method(HTTPMethod.POST)
	void postRuleSet(string _name, string source);

	@path("/api/v1/rules/:name") @method(HTTPMethod.PUT)
	string evalRuleSet(string _name, string source, string input);
}

class RuleProvider : IRuleProvider 
{

	private:
		Rebindable!(immutable RuleNode)[string] ruleSetsByName;

	public:
		this() {

		}
		
		override:

			void postRuleSet(string name, string source)
			{		
				writeln(name);
				auto context = new Context();

				try {
					auto optRule = name in ruleSetsByName;

					if (optRule is null) {
						writeln("Rule does not exist: Creating...");
					} else {
						writeln("Rule already exists: Updating...");
					}

					auto ruleNode = new Tokenizer(new DCharReader(source)).parseRule().expandOperators().interpret(context);
					ruleSetsByName[name] = ruleNode;
				
				} catch (SourceException exception) {
					writeln(exception.getErrorInformation(source).toString());
				}
			}

			string evalRuleSet(string name, string source, string input)
			{
				auto context = new Context();
				writeln(input);
				writeln(source);
				try {
					auto ruleNode = new Tokenizer(new DCharReader(source)).parseRule().expandOperators().interpret(context);
					auto jsonInput = parseJSON(input);
					auto jsonOutput = ruleNode.runRule(jsonInput);
					
					if (jsonOutput.isNull) {
						writeln("Rule not applicable");
						return "Rule not applicable";
					} else {
						writeln("Applying Rule: " ~ name);
						return jsonOutput.get().toString();
					}				
				} catch (SourceException exception) {
					writeln(exception.getErrorInformation(source).toString());
					return exception.getErrorInformation(source).toString();
				}
			}*/

			/*Nullable!JSONValue evalRuleSet(string name, string input)
			{
				writeln("Interpret: "~name);
				
				auto optRule = name in rules.ruleSetsByName;

				if (optRule !is null) { 
					auto rule = *optRule;
					auto jsonInput = parseJSON(input);
					auto jsonOutput = rule.runRule(jsonInput);
					
					if (jsonOutput.isNull) {
						writeln("Rule not applicable");
						return Nullable!JSONValue();
					} else {
						writeln("Applying Rule: " ~ name);
						return jsonOutput;
					}
				} else {
					return Nullable!JSONValue();
				}
			}
}*/

shared static this()
{
	auto router = new URLRouter;
	//router.registerRestInterface(new RuleProvider);
	router
		//.post("/api/v1/rules/:ruleset", &newRuleSet)
		.put("/api/v1/rules/:ruleset", &interpret);		

	auto settings = new HTTPServerSettings;
	settings.port = 8080;
	settings.bindAddresses = ["::1", "127.0.0.1"];

	listenHTTP(settings, router);

	logInfo("Please open http://127.0.0.1:8080/ in your browser.");
}


void interpret(HTTPServerRequest req, HTTPServerResponse res)
{
	auto input = req.json["input"].get!string;
	auto rules = req.json["source"].get!string;
	
    auto jsonInput = parseJSON(input);
    auto source = rules;

    auto context = new Context();
    auto ruleNode = new Tokenizer(new DCharReader(source)).parseRule().expandOperators().interpret(context);
    auto jsonOutput = ruleNode.runRule(jsonInput);
    if (jsonOutput.isNull) {
        writeln("Rule not applicable");
		writeBody("Rule not applicable","application/json; charset=UTF-8");
    } else {
		auto output = jsonOutput.get();
		res.writeBody(output.toString(),"application/json; charset=UTF-8");
    }
}

/*
void newRuleSet(HTTPServerRequest req, HTTPServerResponse res)
{
	writeln("New RuleSet: "~req.params["ruleset"]);
	
	auto ruleName = req.params["ruleset"];
	auto source = req.json["rules"].get!string;
    auto context = new Context();

	try {
		auto optRule = ruleName in ruleSetsByName;

		if (optRule is null) {
			writeln("Rule does not exist: Creating...");
		} else {
			writeln("Rule already exists: Updating...");
		}

		auto ruleNode = new Tokenizer(new DCharReader(source)).parseRule().expandOperators().interpret(context);
		ruleSetsByName[ruleName] = ruleNode;
	
	} catch (SourceException exception) {
    	writeln(exception.getErrorInformation(source).toString());
		res.writeBody(exception.getErrorInformation(source).toString(),"application/json; charset=UTF-8");
    }

	res.writeBody("Rule created!");
}

void interpret(HTTPServerRequest req, HTTPServerResponse res)
{
	writeln("Interpret: "~req.params["ruleset"]);
	
	auto ruleName = req.params["ruleset"];
	auto optRule = ruleName in ruleSetsByName;

	if (optRule !is null) { 
		auto rule = *optRule;
		auto input = req.json["input"].get!string;
		auto jsonInput = parseJSON(input);
		auto jsonOutput = rule.runRule(jsonInput);
		
		if (jsonOutput.isNull) {
			writeln("Rule not applicable");
			res.writeBody("Rule not applicable!");
		} else {
			writeln("Applying Rule: " ~ ruleName);
			auto output = jsonOutput.get();
			res.writeBody(output.toString(),"application/json; charset=UTF-8");
		}
	} else { 
		res.writeBody("Rule doesn't exist!");
	}
}*/