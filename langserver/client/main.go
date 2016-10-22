package main

import (
	"github.com/michael-golfi/go-thrift"
	"github.com/michael-golfi/rules/langserver/client/interpreter"
    "flag"
    "fmt"
    "os"
)

func NewLanguageClient(transportFactory thrift.TTransportFactory, protocolFactory thrift.TProtocolFactory, addr string) (*interpreter.LanguageClient, error) {
	socket, err := thrift.NewTSocket(addr)
	if err != nil {
		return nil, err
	}

	transport := transportFactory.GetTransport(socket)
	defer transport.Close()
	if err := transport.Open(); err != nil {
		return nil, err
	}

	client := interpreter.NewLanguageClientFactory(transport, protocolFactory)
	return client, nil
}

func main() {

    addr := flag.String("addr", "localhost:9090", "The address of the thrift server component (eg: localhost:9090)")
    transportFactory := thrift.NewTFramedTransportFactory(thrift.NewTTransportFactory())
	protocolFactory := thrift.NewTBinaryProtocolFactoryDefault()
	client, err := NewLanguageClient(transportFactory, protocolFactory, *addr)
	if err != nil {
		panic(err)
	}

    args := os.Args[1:]
    
    res,err := client.Interprete(args[0])
    if err != nil {
        panic(err)
    }

    fmt.Println(res)
}