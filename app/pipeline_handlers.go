package app

import (
	"net/http"
	"github.com/gorilla/mux"
	"github.com/michael-golfi/rules/app/api"
	"encoding/json"
)

func HealthCheck(w http.ResponseWriter, r *http.Request) {
	w.Write([]byte("Not Implemented"))
}

func ReadPipelineConfig(w http.ResponseWriter, r *http.Request) {
	w.Write([]byte("Not Implemented"))
}

func Evaluate(w http.ResponseWriter, r *http.Request) {
	//namespace := mux.Vars(r)["namespace"]
	pipelineName := mux.Vars(r)["pipeline_name"]

	var input interface{}
	if err := json.NewDecoder(r.Body).Decode(input); err != nil {
		engine := api.GetEngine()
		engine.EvaluateData(pipelineName, input)
	}
}

func SavePipeline(w http.ResponseWriter, r *http.Request) {
	//namespace := mux.Vars(r)["namespace"]
	pipelineName := mux.Vars(r)["pipeline_name"]

	engine := api.GetEngine()

	process := func(input interface{}) interface{} {
		return input
	}

	pipeline := api.NewPipeline(pipelineName, process)

	engine.Save(pipeline)
}

func DeletePipeline(w http.ResponseWriter, r *http.Request) {
	pipelineName := mux.Vars(r)["pipeline_name"]
	engine := api.GetEngine()
	engine.Delete(pipelineName)
}