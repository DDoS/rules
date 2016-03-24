module ruleslang.syntax.source;

import std.utf : decode;

public class DCharReader {
    private enum size_t DEFAULT_COLLECT_SIZE = 16;
    private string source;
    private size_t index = 0;
    private dchar headChar;
    private bool ahead = false;
    private size_t charCount = 0;
    private dchar[] collected;
    private size_t collectedCount = 0;

    public this(string source) {
        this.source = source;
        collected = new dchar[DEFAULT_COLLECT_SIZE];
    }

    public bool has() {
        return index < source.length || ahead && headChar != '\u0004';
    }

    public dchar head() {
        if (!ahead) {
            if (index < source.length) {
                headChar = source.decode(index);
            } else {
                headChar = '\u0004';
            }
            ahead = true;
        }
        return headChar;
    }

    @property public size_t count() {
        return charCount;
    }

    public void advance() {
        head();
        ahead = false;
        charCount = index;
    }

    public void collect() {
        collected[collectedCount++] = head();
        if (collectedCount >= collected.length) {
            collected.length *= 2;
        }
        ahead = false;
        charCount = index;
    }

    public dstring peekCollected() {
        return collected[0 .. collectedCount].idup;
    }

    public dstring popCollected() {
        auto cs = peekCollected();
        collected = new dchar[DEFAULT_COLLECT_SIZE];
        collectedCount = 0;
        return cs;
    }
}

unittest {
    auto reader = new DCharReader("this is a test to see héhé∑");
    while (reader.head() != ' ') {
        reader.advance();
    }
    while (reader.head() != 'h') {
        reader.collect();
    }
    assert(reader.popCollected() == " is a test to see "d);
    while (reader.has()) {
        reader.collect();
    }
    assert(reader.popCollected() == "héhé∑"d);
}
