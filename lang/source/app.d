import std.stdio;

import ruleslang.syntax.source;
import ruleslang.syntax.token;
import ruleslang.syntax.tokenizer;
import ruleslang.syntax.ast.statement;
import ruleslang.syntax.parser.statement;
import ruleslang.semantic.opexpand;
import ruleslang.semantic.tree;
import ruleslang.semantic.context;
import ruleslang.semantic.interpret;

void main() {
	/*import ruleslang.semantic.context;
	import ruleslang.semantic.type;
	import ruleslang.evaluation.value;

	immutable(Type)[] argumentTypes = [];
	argumentTypes ~= new immutable IntegerLiteralType(125L);
	argumentTypes ~= new immutable IntegerLiteralType(4L);
	auto funcs1 = new IntrinsicNameSpace().getFunctions(OperatorFunction.LEFT_SHIFT_FUNCTION, argumentTypes);
	stdout.writeln(funcs1);

	argumentTypes.length = 0;
	argumentTypes ~= new immutable BooleanLiteralType(false);
	argumentTypes ~= new immutable IntegerLiteralType(12L);
	argumentTypes ~= new immutable FloatLiteralType(1f);
	auto funcs2 = new IntrinsicNameSpace().getFunctions(OperatorFunction.CONDITIONAL_FUNCTION, argumentTypes);
	stdout.writeln(funcs2);*/

	auto context = new Context();
	while (true) {
		stdout.write("> ");
		auto source = stdin.readln();
		if (source.length <= 0) {
			stdout.writeln();
			break;
		}
		try {
			auto tokenizer = new Tokenizer(new DCharReader(source));
		    foreach (statement; tokenizer.parseStatements()) {
				statement = statement.expandOperators();
				stdout.writeln(statement.toString());
				auto assignment = cast(Assignment) statement;
				if (assignment) {
					auto node = assignment.value.interpret(context);
					if (cast(NullNode) node is null) {
						stdout.writeln("RHS semantic: ", node.toString());
					}
					auto typedNode = cast(immutable(TypedNode)) node;
					if (typedNode) {
						stdout.writeln("RHS type: ", typedNode.getType().toString());
					}
				}
		    }
		} catch (SourceException exception) {
			writeln(exception.getErrorInformation(source).toString());
		}
	}
}
