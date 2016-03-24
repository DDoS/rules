module ruleslang.syntax.ast.type;

import std.algorithm.iteration : map, reduce;

import ruleslang.syntax.dchars;
import ruleslang.syntax.source;
import ruleslang.syntax.token;
import ruleslang.syntax.ast.expression;
import ruleslang.syntax.ast.mapper;

public interface Type : SourceIndexed {
    public Type accept(ExpressionMapper mapper);
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

    public override Type accept(ExpressionMapper mapper) {
        foreach (i, dimension; dimensions) {
            dimensions[i] = dimension.accept(mapper);
        }
        return mapper.mapNamedType(this);
    }

    public override string toString() {
        auto componentName = name.join!(".", "getSource()")();
        auto dimensionsString = dimensions.length <= 0 ? "" :
            dimensions.map!"a is null ? \"\" : a.toString()"().map!"\"[\" ~ a ~ \"]\""().reduce!"a ~ b"();
        return componentName ~ dimensionsString;
    }
}
