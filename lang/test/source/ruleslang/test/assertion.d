module ruleslang.test.assertion;

import std.format : format;

public void assertEqual(T)(T a, T b) {
    if (a != b) {
        throw new AssertionError(format("%s != %s", a, b));
    }
}

public class AssertionError : Error {
    public this(string message) {
        super(message);
    }
}
