package api

import (
	"github.com/gorilla/mux"
	"github.com/michael-golfi/rules/http/api/rule"
	"github.com/michael-golfi/rules/http/api/pipeline"
)

type Handler struct {

}

func NewHandler() *Handler {
	return &Handler{}
}

func (h *Handler) SetRoutes(r *mux.Router) {
	pipelineHandler := &pipeline.PipelineHandler{}
	pipelineHandler.SetRoutes(r)

	ruleHandler := &rule.RuleHandler{}
	ruleHandler.SetRoutes(r)
}