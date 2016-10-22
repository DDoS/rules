package interpreter

import (
	"github.com/michael-golfi/go-thrift"
	"github.com/michael-golfi/rules/server/interpreter/client"
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
	return &client, nil
}
