import std.stdio;
import std.json;
import std.typecons : Rebindable, Nullable;

import vibe.d;

import ruleslang.syntax.source;
import ruleslang.syntax.tokenizer;
import ruleslang.syntax.parser.rule;
import ruleslang.semantic.opexpand;
import ruleslang.semantic.interpret;
import ruleslang.semantic.tree;
import ruleslang.evaluation.runtime;
import ruleslang.util;

shared static this() {
    RuleManager manager;

    auto router = new URLRouter();
    router.post("/api/v1/rules/add", &manager.addRule);
    router.post("/api/v1/rules/run", &manager.runRule);

    auto settings = new HTTPServerSettings();
    settings.port = 9090;
    settings.bindAddresses = ["0.0.0.0"];

    listenHTTP(settings, router);
}

/*
curl -X POST -d $'name=test&source=def R: {sint64 i}\nthen(R r):\n return r' http://127.0.0.1:8080/api/v1/rules/add
curl -X POST -d $'name=test&input={"i": 1}' http://127.0.0.1:8080/api/v1/rules/run
*/

private struct RuleManager {
    private Rebindable!(immutable RuleNode)[string] rulesByName;

    void addRule(HTTPServerRequest req, HTTPServerResponse res) {
    	writeln("Adding rule: " ~ req.form["name"]);

    	auto ruleName = req.form["name"];
    	auto ruleSource = req.form["source"];

        try {
            auto ruleNode = new Tokenizer(new DCharReader(ruleSource)).parseRule().expandOperators().interpret();
            rulesByName[ruleName] = ruleNode;
        } catch (SourceException exception) {
            auto errorMessage = exception.getErrorInformation(ruleSource).toString();
            res.writeBody(errorMessage);
            writeln(errorMessage);
        }

        res.writeBody("");
    }

    void runRule(HTTPServerRequest req, HTTPServerResponse res) {
        writeln("Running rule: " ~ req.form["name"]);

    	auto ruleName = req.form["name"];
    	auto ruleNode = rulesByName[ruleName];
    	auto inputString = req.form["input"];
    	auto jsonInput = parseJSON(inputString);

        Nullable!(JSONValue) jsonOutput;
        try {
            jsonOutput = ruleNode.runRule(jsonInput);
        } catch (SourceException exception) {
            auto errorMessage = exception.msg;
            auto startSourceIndex = exception.start;
            auto endSourceIndex = exception.end;
            // TODO: handle runtime error caused by rule
        }

    	if (jsonOutput.isNull) {
            res.writeBody("Rule not applicable");
        } else {
    		auto output = jsonOutput.get();
    		res.writeBody(output.toString(), "application/json; charset=UTF-8");
        }
    }
}
