package main

import (
	"github.com/michael-golfi/go-http-utils"
	"github.com/michael-golfi/log4go"
	"net/http"
	"github.com/michael-golfi/rules/http/api"
	"github.com/docker/docker/vendor/src/github.com/gorilla/mux"
	"github.com/michael-golfi/rules/http/api/pipeline"
	"github.com/michael-golfi/rules/http/api/rule"
)

func main() {
	router := mux.NewRouter()

	handler := api.NewHandler()
	handler.SetRoutes(router)
	
	log4go.Crash(http.ListenAndServe(":8080", router))
}