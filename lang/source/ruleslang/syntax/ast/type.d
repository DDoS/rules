module ruleslang.syntax.ast.type;

import std.format : format;
import std.algorithm.iteration : map, reduce;

import ruleslang.syntax.source;
import ruleslang.syntax.token;
import ruleslang.syntax.ast.expression;
import ruleslang.syntax.ast.mapper;
import ruleslang.semantic.context;
import ruleslang.semantic.type;
import ruleslang.semantic.context;
import ruleslang.semantic.interpret;

import ruleslang.util;

public interface TypeAst {
    @property public size_t start();
    @property public size_t end();
    @property public void start(size_t start);
    @property public void end(size_t end);
    public TypeAst map(ExpressionMapper mapper);
    public immutable(Type) interpret(Context context);
    public string toString();
}

public class NamedTypeAst : TypeAst {
    private Identifier _name;
    private Expression[] _dimensions;

    public this(Identifier name, Expression[] dimensions, size_t end) {
        _name = name;
        _dimensions = dimensions;
        _start = name.start;
        _end = end;
    }

    @property public Identifier name() {
        return _name;
    }

    @property public Expression[] dimensions() {
        return _dimensions;
    }

    mixin sourceIndexFields;

    public override TypeAst map(ExpressionMapper mapper) {
        foreach (i, dimension; _dimensions) {
            _dimensions[i] = dimension is null ? null : dimension.map(mapper);
        }
        return mapper.mapNamedType(this);
    }

    public override immutable(Type) interpret(Context context) {
        return Interpreter.INSTANCE.interpretNamedType(context, this);
    }

    public override string toString() {
        auto dimensionsString = _dimensions.join!("", "\"[\" ~ (a is null ? \"\" : a.toString()) ~ \"]\"");
        return _name.getSource() ~ dimensionsString;
    }
}

public class AnyTypeAst : TypeAst {
    public this(size_t start, size_t end) {
        _start = start;
        _end = end;
    }

    mixin sourceIndexFields;

    public override TypeAst map(ExpressionMapper mapper) {
        return mapper.mapAnyType(this);
    }

    public override immutable(AnyType) interpret(Context context) {
        return Interpreter.INSTANCE.interpretAnyType(context, this);
    }

    public override string toString() {
        return "{}";
    }
}

public class TupleTypeAst : TypeAst {
    private TypeAst[] _memberTypes;

    public this(TypeAst[] memberTypes, size_t start, size_t end) {
        _memberTypes = memberTypes;
        _start = start;
        _end = end;
    }

    @property public TypeAst[] memberTypes() {
        return _memberTypes;
    }

    mixin sourceIndexFields;

    public override TypeAst map(ExpressionMapper mapper) {
        foreach (i, memberType; _memberTypes) {
            _memberTypes[i] = memberType.map(mapper);
        }
        return mapper.mapTupleType(this);
    }

    public override immutable(TupleType) interpret(Context context) {
        return Interpreter.INSTANCE.interpretTupleType(context, this);
    }

    public override string toString() {
        return format("{%s}", _memberTypes.join!", "());
    }
}

public class StructTypeAst : TypeAst {
    private TypeAst[] _memberTypes;
    private Identifier[] _memberNames;

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

    mixin sourceIndexFields;

    public override TypeAst map(ExpressionMapper mapper) {
        foreach (i, memberType; _memberTypes) {
            _memberTypes[i] = memberType.map(mapper);
        }
        return mapper.mapStructType(this);
    }

    public override immutable(StructureType) interpret(Context context) {
        return Interpreter.INSTANCE.interpretStructType(context, this);
    }

    public override string toString() {
        return format("{%s}", stringZip!(" ", ".toString()", ".getSource()")(_memberTypes, _memberNames).join!", "());
    }
}
