module ruleslang.syntax.source;

import std.utf : decode;
import std.string : stripRight;
import std.algorithm.comparison : min;

import ruleslang.syntax.dchars;

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

public interface SourceIndexed {
    @property public size_t start();
    @property public size_t end();
}

public class SourceException : Exception, SourceIndexed {
    private string offender = null;
    private size_t _start;
    private size_t _end;

    public this(string message, dchar offender, size_t index) {
        super(message);
        this.offender = offender.escapeChar().to!string();
        _start = index;
        _end = index;
    }

    public this(string message, SourceIndexed problem) {
        super(message);
        _start = problem.start;
        _end = problem.end;
    }

    @property public override size_t start() {
        return _start;
    }

    @property public override size_t end() {
        return _start;
    }

    public immutable(ErrorInformation)* getErrorInformation(string source) {
        // find the line number the error occurred on
        size_t lineNumber = findLine(source, min(_start, source.length - 1));
        // find start and end of line containing the offender
        ptrdiff_t lineStart = _start, lineEnd = _start;
        while (--lineStart >= 0 && !source[lineStart].isNewLineChar()) {
        }
        lineStart++;
        while (++lineEnd < source.length && !source[lineEnd].isNewLineChar()) {
        }
        lineEnd--;
        string line = source[lineStart .. min(lineEnd + 1, $)].stripRight();
        return new ErrorInformation(this.msg, offender, line, lineNumber, _start - lineStart, _end - lineStart);
    }

    private static size_t findLine(string source, size_t index) {
        size_t line = 0;
        for (size_t i = 0; i <= index; i++) {
            if (source[i].isNewLineChar()) {
                consumeNewLine(source, i);
                line++;
            }
        }
        return line;
    }

    private static void consumeNewLine(string source, ref size_t i) {
        if (source[i] == '\n') {
            // LF
            i++;
        } else if (source[i] == '\r') {
            // CR
            i++;
            if (i < source.length && source[i] == '\n') {
                // CR LF
                i++;
            }
        }
    }

    public immutable struct ErrorInformation {
        public string message;
        public string offender;
        public string line;
        public size_t lineNumber;
        public size_t startIndex;
        public size_t endIndex;

        public string toString() {
            char[] buffer = [];
            buffer.reserve(256);
            buffer ~= "Error: \"" ~ message ~ '"';
            if (offender != null) {
                buffer ~= " caused by '" ~ offender ~ '\'';
            }
            buffer ~= " at line: " ~ lineNumber.to!string ~ ", index: " ~ startIndex.to!string;
            if (startIndex != endIndex) {
                buffer ~= " to " ~ endIndex.to!string;
            }
            buffer ~= " in \n" ~ line ~ '\n';
            foreach (i; 0 .. startIndex) {
                buffer ~= ' ';
            }
            if (startIndex == endIndex) {
                buffer ~= '^';
            } else {
                for (size_t i = startIndex; i <= endIndex; i++) {
                    buffer ~= '~';
                }
            }
            return buffer.idup;
        }
    }
}
