package main

import (
	"github.com/michael-golfi/log4go"
	"net/http"
	"github.com/gorilla/mux"
	"github.com/michael-golfi/rules/server/pipeline"
	"github.com/rs/cors"
)

const (
	rulesUri = "http://127.0.0.1:9090/api/v1/rules"
	file = "pipeline/config/config.example.yaml"
)

func main() {
	router := mux.NewRouter()

	pipeline := pipeline.NewPipelineHandler(rulesUri, file)
	pipeline.SetRoutes(router)

	handler := cors.Default().Handler(router)
	log4go.Crash(http.ListenAndServe(":8080", handler))
}
