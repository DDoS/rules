package inference

import (
	"net/http"
	"encoding/json"
	"io/ioutil"
	"github.com/michael-golfi/log4go"
	"github.com/gorilla/mux"
)

type Field struct {
	Name      string `yaml:"Name"`
	Type      string `yaml:"Type"`
	SubObject []Field `yaml:"SubObject,omitempty"`
}

func SetRoutes(r *mux.Router) {
	r.HandleFunc("/infer", InferJsonStructure)
}

func InferJsonStructure(w http.ResponseWriter, r *http.Request) {
	b, err := ioutil.ReadAll(r.Body)
	if err != nil {
		log4go.Error(err)
	}

	jsonSchema := ParseSchema(b)
	if err := json.NewEncoder(w).Encode(jsonSchema); err != nil {
		log4go.Error(err)
	}
}