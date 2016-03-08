package main

import (
	"fmt"
	"os"
    "os/signal"
    "github.com/michael-golfi/rules/lang"
)

func main() {
    c := make(chan os.Signal, 1)
    signal.Notify(c, os.Interrupt)
    go func(){
        <- c
        fmt.Fprintln(os.Stdin, "\nBye.")
        os.Exit(0)
    }()
    for {
        parseLine()
    }
}

func parseLine() {
    defer func() {
        if err := recover(); err != nil {
            fmt.Println("Parse error:", err)
        }
    }()
    fmt.Fprint(os.Stdin, "> ")
    tokenizer := lang.ReadLineTokenizer(os.Stdin)
    for _, statement := range lang.ParseStatments(tokenizer) {
        fmt.Fprintln(os.Stdin, statement.String())
    }
}
