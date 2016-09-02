module ruleslang.syntax.ast.type;

import std.algorithm.iteration : map, reduce;

import ruleslang.syntax.source;
import ruleslang.syntax.token;
import ruleslang.syntax.ast.expression;
import ruleslang.syntax.ast.mapper;

import ruleslang.util;

public interface Type {
    @property public size_t start();
    @property public size_t end();
    public Type map(ExpressionMapper mapper);
    public string toString();
}

public class NamedType : Type {
    private Identifier[] name;
    private Expression[] dimensions;
    private size_t _end;

    public this(Identifier[] name, Expression[] dimensions, size_t end) {
        this.name = name;
        this.dimensions = dimensions;
        _end = end;
    }

    @property public override size_t start() {
        return name[0].start;
    }

    @property public override size_t end() {
        return _end;
    }

    public override Type map(ExpressionMapper mapper) {
        foreach (i, dimension; dimensions) {
            dimensions[i] = dimension is null ? null : dimension.map(mapper);
        }
        return mapper.mapNamedType(this);
    }

    public override string toString() {
        auto componentName = name.join!(".", "a.getSource()")();
        auto dimensionsString = dimensions.join!("", "\"[\" ~ (a is null ? \"\" : a.toString()) ~ \"]\"");
        return componentName ~ dimensionsString;
    }
}
