package main

import (
	"net/http"

	"github.com/gorilla/mux"
	"github.com/michael-golfi/log4go"
	"github.com/michael-golfi/rules/server/pipeline"
	"github.com/rs/cors"
	"os"
)

const (
	rulesURI = "http://127.0.0.1:9090/api/v1/rules"
	dir      = "config/"
)

func main() {
	router := mux.NewRouter()

	val, err := os.LookupEnv("RULES_BASE_URI")
	if err != nil {
		log4go.Crash("Cannot parse rules uri")
	}

	pipeline := pipeline.NewPipelineHandler(val, dir)
	pipeline.SetRoutes(router)

	handler := cors.Default().Handler(router)
	log4go.Info("Starting Ledgr on port 8080")
	log4go.Crash(http.ListenAndServe(":8080", handler))
}
