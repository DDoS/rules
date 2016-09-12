module ruleslang.syntax.ast.type;

import std.format : format;
import std.algorithm.iteration : map, reduce;

import ruleslang.syntax.source;
import ruleslang.syntax.token;
import ruleslang.syntax.ast.expression;
import ruleslang.syntax.ast.mapper;

import ruleslang.util;

public interface TypeAst {
    @property public size_t start();
    @property public size_t end();
    public TypeAst map(ExpressionMapper mapper);
    public string toString();
}

public class NamedTypeAst : TypeAst {
    private Identifier[] _name;
    private Expression[] _dimensions;
    private size_t _end;

    public this(Identifier[] name, Expression[] dimensions, size_t end) {
        _name = name;
        _dimensions = dimensions;
        _end = end;
    }

    @property public Identifier[] name() {
        return _name;
    }

    @property public Expression[] dimensions() {
        return _dimensions;
    }

    @property public override size_t start() {
        return _name[0].start;
    }

    @property public override size_t end() {
        return _end;
    }

    public override TypeAst map(ExpressionMapper mapper) {
        foreach (i, dimension; _dimensions) {
            _dimensions[i] = dimension is null ? null : dimension.map(mapper);
        }
        return mapper.mapNamedTypeAst(this);
    }

    public override string toString() {
        auto componentName = _name.join!(".", "a.getSource()")();
        auto dimensionsString = _dimensions.join!("", "\"[\" ~ (a is null ? \"\" : a.toString()) ~ \"]\"");
        return componentName ~ dimensionsString;
    }
}

public class AnyTypeAst : TypeAst {
    private size_t _start;
    private size_t _end;

    public this(size_t start, size_t end) {
        _start = start;
        _end = end;
    }

    @property public override size_t start() {
        return _start;
    }

    @property public override size_t end() {
        return _end;
    }

    public override TypeAst map(ExpressionMapper mapper) {
        return mapper.mapAnyTypeAst(this);
    }

    public override string toString() {
        return "{}";
    }
}

public class TupleTypeAst : TypeAst {
    private TypeAst[] _memberTypes;
    private size_t _start;
    private size_t _end;

    public this(TypeAst[] memberTypes, size_t start, size_t end) {
        _memberTypes = memberTypes;
        _start = start;
        _end = end;
    }

    @property public TypeAst[] memberTypes() {
        return _memberTypes;
    }

    @property public override size_t start() {
        return _start;
    }

    @property public override size_t end() {
        return _end;
    }

    public override TypeAst map(ExpressionMapper mapper) {
        foreach (i, memberType; _memberTypes) {
            _memberTypes[i] = memberType.map(mapper);
        }
        return mapper.mapTupleTypeAst(this);
    }

    public override string toString() {
        return format("{%s}", _memberTypes.join!", "());
    }
}

public class StructTypeAst : TypeAst {
    private TypeAst[] _memberTypes;
    private Identifier[] _memberNames;
    private size_t _start;
    private size_t _end;

    public this(TypeAst[] memberTypes, Identifier[] memberNames, size_t start, size_t end) {
        assert (memberTypes.length == memberNames.length);
        _memberTypes = memberTypes;
        _memberNames = memberNames;
        _start = start;
        _end = end;
    }

    @property public TypeAst[] memberTypes() {
        return _memberTypes;
    }

    @property public Identifier[] memberNames() {
        return _memberNames;
    }

    @property public override size_t start() {
        return _start;
    }

    @property public override size_t end() {
        return _end;
    }

    public override TypeAst map(ExpressionMapper mapper) {
        foreach (i, memberType; _memberTypes) {
            _memberTypes[i] = memberType.map(mapper);
        }
        return mapper.mapStructTypeAst(this);
    }

    public override string toString() {
        return format("{%s}", stringZip!(" ", ".toString()", ".getSource()")(_memberTypes, _memberNames).join!", "());
    }
}
