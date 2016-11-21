package main

import (
	"github.com/michael-golfi/log4go"
	"net/http"
	"github.com/gorilla/mux"
	"github.com/michael-golfi/rules/server/pipeline"
	"github.com/rs/cors"
)

const (
	etcd = "http://52.229.124.202:2379"
	file = "pipeline/config/config.example.yaml"
)

func main() {
	router := mux.NewRouter()

	pipeline := pipeline.NewPipelineHandler(etcd, file)
	pipeline.SetRoutes(router)

	handler := cors.Default().Handler(router)
	log4go.Crash(http.ListenAndServe(":8080", handler))
}
