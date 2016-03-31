module ruleslang.util;

import std.array : array;
import std.algorithm.searching : canFind, findAmong;
import std.algorithm.iteration : uniq;

public T castOrFail(T, S)(S s) {
    T t = cast(T) s;
    if (t is null) {
        throw new Exception("Cannot cast " ~ __traits(identifier, S) ~ " to " ~ __traits(identifier, T));
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
