package app

import (
	"net/http"
	"github.com/michael-golfi/rules/app/api"
	"github.com/michael-golfi/log4go"
	"fmt"
	"encoding/json"
)

func HealthCheck(w http.ResponseWriter, r *http.Request) {
	switch api.Default.Info() {
	case api.RUNNING:
		w.Write([]byte("ok"))
	case api.UNSTARTED:
		w.WriteHeader(http.StatusNotModified)
	case api.STOPPED:
		w.WriteHeader(http.StatusServiceUnavailable)
	}
}

func ReadPipelineConfig(w http.ResponseWriter, r *http.Request) {
	if err := json.NewEncoder(w).Encode(api.Default); err != nil {
		message := fmt.Sprintf("Could not read Pipeline: %s", err.Error())

		log4go.Error(message)
		w.WriteHeader(http.StatusInternalServerError)
		w.Write([]byte(message))
	}
}

func Evaluate(w http.ResponseWriter, r *http.Request) {
	state := api.Default.Info()
	switch state {
	case api.UNSTARTED:
		api.Default.Run(func(input interface{}) {
			log4go.Info("Executing: %s", input)
		})
	
	case api.RUNNING:
		api.Default.Input(r.Body)

	case api.STOPPED:
		w.Write([]byte("Pipeline Stopped"))
		w.WriteHeader(http.StatusMethodNotAllowed)
	}
}