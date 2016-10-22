package main

import (
	"github.com/michael-golfi/log4go"
	"net/http"
	"github.com/gorilla/mux"
	"github.com/michael-golfi/rules/server/interpreter"
	"github.com/michael-golfi/rules/server/pipeline"
	"github.com/rs/cors"
)

func main() {
	router := mux.NewRouter()
	setRoutes(router)
	handler := cors.Default().Handler(router)
	log4go.Crash(http.ListenAndServe(":8081", handler))
}

func setRoutes(r *mux.Router) {
	compiler := interpreter.NewHandler("localhost:9090")
	pipeline := pipeline.PipelineHandler{}

	compiler.SetRoutes(r)
	pipeline.SetRoutes(r)
}