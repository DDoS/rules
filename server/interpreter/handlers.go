package interpreter

import (
	"github.com/gorilla/mux"
	"net/http"
	"encoding/json"
	"github.com/michael-golfi/log4go"
	"github.com/michael-golfi/go-thrift"
	"github.com/michael-golfi/rules/server/interpreter/client"
)

type Handler struct {
	LanguageClient *interpreter.LanguageClient
}

type program struct {
	Code string
}

func NewHandler(addr string) *Handler {
	transportFactory := thrift.NewTFramedTransportFactory(thrift.NewTTransportFactory())
	protocolFactory := thrift.NewTBinaryProtocolFactoryDefault()
	client, err := NewLanguageClient(transportFactory, protocolFactory, addr)
	if err != nil {
		log4go.Crashf("Could not create new language client: %s", err.Error())
	}

	return &Handler{
		LanguageClient: client,
	}
}

func (h *Handler) SetRoutes(r *mux.Router) {
	r.HandleFunc("/interprete", h.Interprete)
}

func (h *Handler) Interprete(w http.ResponseWriter, r *http.Request) {
	prog := new(program)
	if err := json.NewDecoder(r.Body).Decode(prog); err != nil {
		log4go.Error("Cannot decode json code: %s", err.Error())
	}

	if err := json.NewEncoder(w).Encode(h.LanguageClient.Interprete(prog.Code)); err != nil {
		log4go.Error("Cannot encode result of code: %s", err.Error())
	}
}