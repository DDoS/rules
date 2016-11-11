module ruleslang.syntax.parser.type;

import ruleslang.syntax.source;
import ruleslang.syntax.token;
import ruleslang.syntax.tokenizer;
import ruleslang.syntax.ast.type;
import ruleslang.syntax.ast.expression;
import ruleslang.syntax.parser.expression;
import ruleslang.util;

private Expression parseArrayDimension(Tokenizer tokens, out size_t end) {
    if (tokens.head() != "[") {
        throw new SourceException("Expected '['", tokens.head());
    }
    tokens.advance();
    if (tokens.head() == "]") {
        end = tokens.head().end;
        tokens.advance();
        return null;
    }
    auto size = parseExpression(tokens);
    if (tokens.head() != "]") {
        throw new SourceException("Expected ']'", tokens.head());
    }
    end = tokens.head().end;
    tokens.advance();
    return size;
}

public NamedTypeAst parseNamedType(Tokenizer tokens) {
    if (tokens.head().getKind() != Kind.IDENTIFIER) {
        throw new SourceException("Expected an identifier", tokens.head());
    }
    auto name = tokens.head().castOrFail!Identifier();
    auto end = name.end;
    tokens.advance();
    Expression[] dimensions = [];
    while (tokens.head() == "[") {
        dimensions ~= parseArrayDimension(tokens, end);
    }
    return new NamedTypeAst(name, dimensions, end);
}

public TypeAst parseCompositeType(Tokenizer tokens) {
    if (tokens.head() != "{") {
        throw new SourceException("Expected '{'", tokens.head());
    }
    auto start = tokens.head().start;
    tokens.advance();
    if (tokens.head() == "}") {
        auto end = tokens.head().end;
        tokens.advance();
        return new AnyTypeAst(start, end);
    }
    TypeAst[] memberTypes = [parseType(tokens)];
    Identifier[] memberNames = [];
    bool structType = false;
    if (tokens.head().getKind() == Kind.IDENTIFIER) {
        memberNames ~= tokens.head().castOrFail!Identifier();
        tokens.advance();
        structType = true;
    }
    while (tokens.head() == ",") {
        tokens.advance();
        memberTypes ~= parseType(tokens);
        if (structType) {
            if (tokens.head().getKind() != Kind.IDENTIFIER) {
                throw new SourceException("Expected identifier", tokens.head());
            }
            memberNames ~= tokens.head().castOrFail!Identifier();
            tokens.advance();
        }
    }
    if (tokens.head() != "}") {
        throw new SourceException("Expected '}'", tokens.head());
    }
    auto end = tokens.head().end;
    tokens.advance();
    if (structType) {
        return new StructTypeAst(memberTypes, memberNames, start, end);
    }
    return new TupleTypeAst(memberTypes, start, end);
}

public TypeAst parseType(Tokenizer tokens) {
    if (tokens.head() == "{") {
        return parseCompositeType(tokens);
    }
    return parseNamedType(tokens);
}
