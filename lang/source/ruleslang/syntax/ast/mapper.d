module ruleslang.syntax.ast.mapper;

import std.traits;

import ruleslang.syntax.ast.expression;

private mixin template Modify(alias Modifier, Modifiers...)
        if (Parameters!Modifier.length == 1 && isImplicitlyConvertible!(Parameters!Modifier[0], Expression)
                && __traits(isSame, ReturnType!Modifier, Expression)) {

    mixin(
        `public Expression modify` ~ __traits(identifier, Parameters!Modifier[0]) ~ `(Parameters!Modifier[0] expression) {
            return Modifier(expression);
        }`
    );

    static if (Modifiers.length > 0) {
        mixin Modify!Modifiers;
    }
}

public template AstMapper(Modifiers...) {
    public class AstMapper {
        mixin Modify!Modifiers;
    }
}
