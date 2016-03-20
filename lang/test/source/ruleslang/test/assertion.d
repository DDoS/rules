module ruleslang.test.assertion;

import std.format;

public void assertEqual(T)(T a, T b) {
    if (a != b) {
        throw new AssertionException(format("%s != %s", a, b));
    }
}

public class AssertionException : Exception {
    public this(string message) {
        super(message);
    }
}
