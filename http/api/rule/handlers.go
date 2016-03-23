package rule

import (
	"net/http"
	"github.com/docker/docker/vendor/src/github.com/gorilla/mux"
)

type RuleHandler struct {

}

func (rh *RuleHandler) SetRoutes(r *mux.Router) {
	r.HandleFunc("/rule", rh.GetRules).Methods("GET")
	r.HandleFunc("/rule", rh.GetRules).Methods("POST")
}

func (rh *RuleHandler) GetRules(w http.ResponseWriter, r *http.Request) {

}

func (rh *RuleHandler) SetRules(w http.ResponseWriter, r *http.Request) {
	
}