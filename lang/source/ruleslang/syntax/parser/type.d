module ruleslang.syntax.parser.type;

import ruleslang.syntax.token;
import ruleslang.syntax.tokenizer;
import ruleslang.syntax.ast.type;
import ruleslang.syntax.ast.expression;
import ruleslang.syntax.parser.expression;

public Identifier[] parseName(Tokenizer tokens) {
    if (tokens.head().getKind() != Kind.IDENTIFIER) {
        throw new Exception("Expected an identifier");
    }
    Identifier[] name = [cast(Identifier) tokens.head()];
    tokens.advance();
    while (tokens.head() == ".") {
        tokens.advance();
        if (tokens.head().getKind() != Kind.IDENTIFIER) {
            throw new Exception("Expected an identifier");
        }
        name ~= cast(Identifier) tokens.head();
        tokens.advance();
    }
    return name;
}

private Expression parseArrayDimension(Tokenizer tokens) {
    if (tokens.head() != "[") {
        throw new Exception("Expected '['");
    }
    tokens.advance();
    if (tokens.head() == "]") {
        tokens.advance();
        return null;
    }
    auto size = parseExpression(tokens);
    if (tokens.head() != "]") {
        throw new Exception("Expected ']'");
    }
    tokens.advance();
    return size;
}

public NamedType parseNamedType(Tokenizer tokens) {
    auto name = parseName(tokens);
    Expression[] dimensions = [];
    while (tokens.head() == "[") {
        dimensions ~= parseArrayDimension(tokens);
    }
    return new NamedType(name, dimensions);
}

public Type parseType(Tokenizer tokens) {
    return parseNamedType(tokens);
}
