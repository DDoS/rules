package main

import (
	"github.com/michael-golfi/log4go"
	"net/http"
	"github.com/gorilla/mux"
	"github.com/michael-golfi/rules/server/http/compiler"
	"github.com/michael-golfi/rules/server/http/pipeline"
	"github.com/michael-golfi/rules/server/http/rule"
)

func main() {
	router := mux.NewRouter()
	setRoutes(router)
	log4go.Crash(http.ListenAndServe(":8080", router))
}

func setRoutes(r *mux.Router) {
	compiler := compiler.Handler{}
	pipeline := pipeline.PipelineHandler{}
	rule := rule.RuleHandler{}

	compiler.SetRoutes(r)
	pipeline.SetRoutes(r)
	rule.SetRoutes(r)
}