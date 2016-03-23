package pipeline

import (
	"net/http"
	"github.com/michael-golfi/log4go"
	"fmt"
	"encoding/json"
	"github.com/gorilla/mux"
)

type PipelineHandler struct {

}

func (p *PipelineHandler) SetRoutes(r *mux.Router) {
	r.HandleFunc("/pipeline", p.ReadPipelineConfig).Methods("GET")
	r.HandleFunc("/pipeline", p.Evaluate).Methods("POST")
}

func (p *PipelineHandler) ReadPipelineConfig(w http.ResponseWriter, r *http.Request) {
	if err := json.NewEncoder(w).Encode(Default); err != nil {
		message := fmt.Sprintf("Could not read Pipeline: %s", err.Error())

		log4go.Error(message)
		w.WriteHeader(http.StatusInternalServerError)
		w.Write([]byte(message))
	}
}

func (p *PipelineHandler) Evaluate(w http.ResponseWriter, r *http.Request) {
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