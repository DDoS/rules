package api

import (
	"net/http"
	"github.com/michael-golfi/log4go"
	"fmt"
	"encoding/json"
)

func HealthCheck(w http.ResponseWriter, r *http.Request) {
	switch Default.Info() {
	case RUNNING:
		w.Write([]byte("ok"))
	case UNSTARTED:
		w.WriteHeader(http.StatusNotModified)
	case STOPPED:
		w.WriteHeader(http.StatusServiceUnavailable)
	}
}

func ReadPipelineConfig(w http.ResponseWriter, r *http.Request) {
	if err := json.NewEncoder(w).Encode(Default); err != nil {
		message := fmt.Sprintf("Could not read Pipeline: %s", err.Error())

		log4go.Error(message)
		w.WriteHeader(http.StatusInternalServerError)
		w.Write([]byte(message))
	}
}

func Evaluate(w http.ResponseWriter, r *http.Request) {
	state := Default.Info()
	switch state {
	case UNSTARTED:
		Default.Run(func(input interface{}) {
			log4go.Info("Executing: %s", input)
		})
	
	case RUNNING:
		Default.Input(r.Body)

	case STOPPED:
		w.Write([]byte("Pipeline Stopped"))
		w.WriteHeader(http.StatusMethodNotAllowed)
	}
}