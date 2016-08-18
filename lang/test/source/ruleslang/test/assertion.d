module ruleslang.test.assertion;

import std.format : format;

public void assertEqual(T)(T a, T b) {
    static if (is(T == interface)) {
        bool equal = a.opEquals(b);
    } else {
        bool equal = a == b;
    }
    if (!equal) {
        throw new AssertionError(format("%s != %s", a, b));
    }
}

public class AssertionError : Error {
    public this(string message) {
        super(message);
    }
}
