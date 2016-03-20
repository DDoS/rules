module ruleslang.syntax.dcharstream;

import std.stdio;
import std.utf;

import ruleslang.syntax.dchars;

public interface DCharStream {
    public bool has();
    public dchar next();
}

public class StringDCharStream : DCharStream {
    private string source;
    private size_t index = 0;

    public this(string source) {
        this.source = source;
    }

    public override bool has() {
        return index < source.length;
    }

    public override dchar next() {
        return source.decode(index);
    }
}

public class ReadLineDCharStream : DCharStream {
    private File file;
    private char[] buffer;
    private dchar headChar;
    private bool ahead = false;

    public this(File file) {
        this.file = file;
        buffer = new char[4];
    }

    public override bool has() {
        return head() != '\u0004';
    }

    public override dchar next() {
        auto c = head();
        ahead = false;
        return c;
    }

    private dchar head() {
        if (!ahead) {
            auto read = file.rawRead(buffer[0 .. 1]);
            if (read.length < 1) {
                headChar = '\u0004';
            } else {
                auto size = read.stride();
                if (size > 1) {
                    read = file.rawRead(buffer[1 .. size]);
                }
                if (read.length < size - 1) {
                    throw new Exception("Invalid unicode sequence, expected more bytes");
                }
                auto sequence = buffer;
                headChar = sequence.decodeFront();
                if (headChar.isNewLineChar()) {
                    headChar = '\u0004';
                }
            }
            ahead = true;
        }
        return headChar;
    }
}

public class DCharReader {
    private enum size_t DEFAULT_COLLECT_SIZE = 16;
    private DCharStream stream;
    private dchar headChar;
    private bool ahead = false;
    private size_t charCount = 0;
    private dchar[] collected;
    private size_t collectedCount = 0;

    public this(DCharStream stream) {
        this.stream = stream;
        collected = new dchar[DEFAULT_COLLECT_SIZE];
    }

    public bool has() {
        return stream.has() || ahead && headChar != '\u0004';
    }

    public dchar head() {
        if (!ahead) {
            headChar = stream.has() ? stream.next() : '\u0004';
            ahead = true;
        }
        return headChar;
    }

    public size_t count() {
        return charCount;
    }

    public void advance() {
        head();
        ahead = false;
        charCount++;
    }

    public void collect() {
        collected[collectedCount++] = head();
        if (collectedCount >= collected.length) {
            collected.length *= 2;
        }
        ahead = false;
        charCount++;
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
    auto reader = new DCharReader(new StringDCharStream("this is a test to see héhé∑"));
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
