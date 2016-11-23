package main

import (
	"net/http"

	"github.com/gorilla/mux"
	"github.com/michael-golfi/log4go"
	"github.com/michael-golfi/rules/server/pipeline"
	"github.com/rs/cors"
)

const (
	rulesURI = "http://127.0.0.1:9090/api/v1/rules"
	dir      = "config/"
)

func main() {
	router := mux.NewRouter()

	pipeline := pipeline.NewPipelineHandler(rulesURI, dir)
	pipeline.SetRoutes(router)

	handler := cors.Default().Handler(router)
	log4go.Info("Starting Ledgr on port 8080")
	log4go.Crash(http.ListenAndServe(":8080", handler))
}
