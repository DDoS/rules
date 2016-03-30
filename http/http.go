package main

import (
	"github.com/michael-golfi/log4go"
	"net/http"
	"github.com/michael-golfi/rules/http/api"
	"github.com/gorilla/mux"
)

func main() {
	router := mux.NewRouter()

	handler := api.NewHandler()
	handler.SetRoutes(router)
	
	log4go.Crash(http.ListenAndServe(":8080", router))
}