module ruleslang.test.assertion;

import std.format : format;

public void assertEqual(T)(T a, T b, string file = __FILE__, size_t line = __LINE__) {
    static if (is(T == interface)) {
        bool equal = a.opEquals(b);
    } else {
        bool equal = a == b;
    }
    if (!equal) {
        throw new AssertionError(format("%s != %s\nin %s line %d", a, b, file, line));
    }
}

public class AssertionError : Error {
    public this(string message) {
        super(message);
    }
}
