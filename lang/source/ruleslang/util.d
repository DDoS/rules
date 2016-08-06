module ruleslang.util;

import std.algorithm.searching : canFind, findAmong;
import std.algorithm.iteration : map, reduce, uniq;
import std.ascii : isAlphaNum, toLower, toUpper;

public T castOrFail(T, S)(S s) {
    T t = cast(T) s;
    if (t is null) {
        throw new Error("Cannot cast " ~ __traits(identifier, S) ~ " to " ~ __traits(identifier, T));
    }
    return t;
}

public immutable(T) exactCastImmutable(T, S)(S s) {
    auto t = cast(immutable T) s;
    if (t is null || typeid(t) != typeid(T)) {
        return null;
    }
    return t;
}

public T[][T] transitiveClosure(T)(T[][T] adjacencies) {
    T[][T] result;
    bool wasReduced = void;
    do {
        wasReduced = false;
        foreach (node; adjacencies.byKey()) {
            auto adjacents = adjacencies[node];
            if (adjacents.findAmong(adjacencies.keys).length <= 0) {
                adjacencies.reduceGraph(result, node, adjacents);
                wasReduced = true;
                break;
            }
        }
    } while (wasReduced && adjacencies.length > 0);
    foreach (node; result.byKey()) {
        result[node] ~= node;
    }
    return result;
}

private void reduceGraph(T)(ref T[][T] adjacencies, ref T[][T] result, T independent, T[] adjacents) {
    adjacencies.remove(independent);
    foreach (node; adjacencies.byKey()) {
        if (adjacencies[node].canFind(independent)) {
            adjacencies[node].addMissing(adjacents);
        }
    }
    result[independent] = adjacents;
}

public void addMissing(T)(ref T[] to, T[] elements) {
    foreach (element; elements) {
        if (!to.canFind(element)) {
            to ~= element;
        }
    }
}

public V[K] inverse(K, V)(K[V] array) {
    V[K] inv;
    foreach (k, v; array) {
        inv[v] = k;
    }
    return inv;
}

public string join(string joiner, string stringer = "toString()", T)(T[] things ...) {
    if (things.length <= 0) {
        return "";
    }
    return things.map!("a." ~ stringer).reduce!("a ~ \"" ~ joiner ~ "\" ~ b")();
}

public string asciiSnakeToCamelCase(string snake, bool upperFirst = false) {
    auto camel = new char[snake.length];
    bool firstWordLetter = upperFirst;
    size_t i = 0;
    foreach (char s; snake) {
        if (s == '_') {
            firstWordLetter = true;
            continue;
        }
        if (!s.isAlphaNum()) {
            throw new Error("Expected only ASCII alphanumeric characters and underscores");
        }
        if (firstWordLetter) {
            s = s.toUpper();
            firstWordLetter = false;
        } else {
            s = s.toLower();
        }
        camel[i++] = s;
    }
    return camel[0 .. i].idup;
}
