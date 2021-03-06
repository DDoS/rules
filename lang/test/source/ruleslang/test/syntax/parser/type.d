module ruleslang.test.parser.type;

import ruleslang.syntax.source;
import ruleslang.syntax.token;
import ruleslang.syntax.tokenizer;
import ruleslang.syntax.parser.type;

import ruleslang.test.assertion;

unittest {
    assertEqual(
        "Test",
        parseTestType("Test")
    );
    assertEqual(
        "Test[]",
        parseTestType("Test[]")
    );
    assertEqual(
        "Test[SignedIntegerLiteral(1)]",
        parseTestType("Test[1]")
    );
    assertEqual(
        "Test[Multiply(SignedIntegerLiteral(1) * SignedIntegerLiteral(3))]",
        parseTestType("Test[1 * 3]")
    );
    assertEqual(
        "Test[][Multiply(SignedIntegerLiteral(1) * SignedIntegerLiteral(3))]",
        parseTestType("Test[][1 * 3]")
    );
    assertEqual(
        "Test[SignedIntegerLiteral(1)][]",
        parseTestType("Test[1][]")
    );
}

unittest {
    assertEqual(
        "{}",
        parseTestType("{}")
    );
    assertEqual(
        "{}",
        parseTestType("{    }")
    );
    assertParseTypeFail("{\r\n}");
    assertEqual(
        "{bool}",
        parseTestType("{bool}")
    );
    assertEqual(
        "{bool, uint8}",
        parseTestType("{bool, uint8}")
    );
    assertEqual(
        "{uint32[]}",
        parseTestType("{uint32[]}")
    );
    assertEqual(
        "{bool b}",
        parseTestType("{bool b}")
    );
    assertEqual(
        "{bool b, uint8 u}",
        parseTestType("{bool b, uint8 u}")
    );
    assertEqual(
        "{uint32[] us}",
        parseTestType("{uint32[] us}")
    );
    assertParseTypeFail("{bool b, bool}");
    assertParseTypeFail("{bool, bool b}");
    assertParseTypeFail("{bool, bool b, bool}");
}

private string parseTestType(string source) {
    auto tokenizer = new Tokenizer(new DCharReader(source));
    if (tokenizer.head().getKind() == Kind.INDENTATION) {
        tokenizer.advance();
    }
    return parseType(tokenizer).toString();
}

private void assertParseTypeFail(string source) {
    try {
        auto type = parseTestType(source);
        throw new AssertionError("Expected a source exception, but got type:\n" ~ type);
    } catch (SourceException exception) {
        debug (verboseTests) {
            import std.stdio : stderr;
            stderr.writeln(exception.getErrorInformation(source).toString());
        }
    }
}
