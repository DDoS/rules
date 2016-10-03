package inference

import (
	"net/http"
	"encoding/json"
	"io/ioutil"
	"github.com/michael-golfi/log4go"
	"github.com/gorilla/mux"
)

type JsonHandler struct {

}

func (j *JsonHandler) SetRoutes(r *mux.Router) {
	r.HandleFunc("/infer", j.InferJsonStructure)
}

func (j *JsonHandler) InferJsonStructure(w http.ResponseWriter, r *http.Request) {
	b, err := ioutil.ReadAll(r.Body)
	if err != nil {
		log4go.Error(err)
	}

	jsonSchema := j.Parse(b)
	if err := json.NewEncoder(w).Encode(jsonSchema); err != nil {
		log4go.Error(err)
	}
}