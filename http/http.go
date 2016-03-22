package main

import (
	"github.com/michael-golfi/go-http-utils"
	"github.com/michael-golfi/log4go"
	"net/http"
	"github.com/michael-golfi/rules/http/api"
)

func main() {
	router := util.NewRouter(api.Routes)
	log4go.Crash(http.ListenAndServe(":8080", router))
}