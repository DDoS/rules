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
        "ca.sapon.Test",
        parseTestType("ca.sapon.Test")
    );
    assertEqual(
        "Test[]",
        parseTestType("Test[]")
    );
    assertEqual(
        "ca.sapon.Test[]",
        parseTestType("ca.sapon.Test[]")
    );
    assertEqual(
        "Test[SignedIntegerLiteral(1)]",
        parseTestType("Test[1]")
    );
    assertEqual(
        "ca.sapon.Test[SignedIntegerLiteral(2)]",
        parseTestType("ca.sapon.Test[2]")
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
    assertParseTypeFail("{\n}");
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
        "{uint32[], ca.sapon.Test}",
        parseTestType("{uint32[], ca.sapon.Test}")
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
    assertEqual(
        "{uint32[] us, ca.sapon.Test sap}",
        parseTestType("{uint32[] us, ca.sapon.Test sap}")
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
