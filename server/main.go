package main

import (
	"github.com/michael-golfi/log4go"
	"net/http"
	"github.com/gorilla/mux"
	"github.com/michael-golfi/rules/server/pipeline"
	"github.com/rs/cors"
)

func main() {
	router := mux.NewRouter()
	setRoutes(router)
	handler := cors.Default().Handler(router)
	log4go.Crash(http.ListenAndServe(":8080", handler))
}

func setRoutes(r *mux.Router) {
	pipeline := pipeline.NewPipelineHandler("http://52.229.124.202:2379", "/pipelines.yaml")
	pipeline.SetRoutes(r)
}