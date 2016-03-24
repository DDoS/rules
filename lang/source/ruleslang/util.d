module ruleslang.util;

public T castOrFail(T, S)(S s) {
    T t = cast(T) s;
    if (t is null) {
        throw new Exception("Cannot cast " ~ __traits(identifier, S) ~ " to " ~ __traits(identifier, T));
    }
    return t;
}
