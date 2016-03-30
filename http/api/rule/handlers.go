package rule

import (
	"net/http"
	"github.com/gorilla/mux"
)

type RuleHandler struct {
	rules Repository
}

func (rh *RuleHandler) SetRoutes(r *mux.Router) {
	r.HandleFunc("/rule", rh.GetRules).Methods("GET")
	r.HandleFunc("/rule", rh.GetRules).Methods("POST")
}

func (rh *RuleHandler) GetRules(w http.ResponseWriter, r *http.Request) {
	w.Write([]byte("Not Implemented"))
}

func (rh *RuleHandler) SetRules(w http.ResponseWriter, r *http.Request) {
	w.Write([]byte("Not Implemented"))
}