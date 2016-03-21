module ruleslang.semantic.litreduce;

import ruleslang.syntax.ast.mapper;
import ruleslang.syntax.ast.expression;

public Expression reduceLiteral(Expression target) {
    auto mapper = new AstMapper!(reduceAdd)();
    return target;
}

public Expression reduceAdd(Add add) {
    import std.stdio;
    writeln(add.toString());
    return add;
}
