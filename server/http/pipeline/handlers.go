package pipeline

import (
	"net/http"
	"github.com/michael-golfi/log4go"
	"fmt"
	"encoding/json"
	"github.com/gorilla/mux"
)

type PipelineHandler struct {
	pipeline *Pipeline
}

func (p *PipelineHandler) SetRoutes(r *mux.Router) {
	r.HandleFunc("/pipeline", p.ReadPipelineConfig).Methods("HEAD")
	r.HandleFunc("/pipeline", p.Evaluate).Methods("POST")
}

func (p *PipelineHandler) ReadPipelineConfig(w http.ResponseWriter, r *http.Request) {
	if err := json.NewEncoder(w).Encode(p.pipeline); err != nil {
		message := fmt.Sprintf("Could not read Pipeline: %s", err.Error())

		log4go.Error(message)
		w.WriteHeader(http.StatusInternalServerError)
		w.Write([]byte(message))
	}
}

func (p *PipelineHandler) Evaluate(w http.ResponseWriter, r *http.Request) {
	state := p.pipeline.State()
	switch state {
	case RUNNING:
		p.pipeline.Input(r.Body)

	case STOPPED:
		w.Write([]byte("Pipeline Stopped"))
		w.WriteHeader(http.StatusMethodNotAllowed)
	}
}