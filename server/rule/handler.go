package rule

import (
	"github.com/gorilla/mux"
	"net/http"
	"github.com/square/go-jose/json"
	"github.com/michael-golfi/log4go"
)

type Handler struct {
	Rules RuleRepository
}

func (h *Handler) SetRoutes(r *mux.Router) {
	r.HandleFunc("/rule", h.Add).Methods(http.MethodPut)
	r.HandleFunc("/rule/{id}", h.Delete).Methods(http.MethodDelete)
}

func (h *Handler) Add(w http.ResponseWriter, r *http.Request) {
	var rules RuleRepository
	if err := json.NewDecoder(r.Body).Decode(&rules); err != nil {
		log4go.Error("Could not decode rule: %s", err.Error())
	}
	h.AddRules(rules)
}

func (h *Handler) Delete(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	id := vars["id"]
	h.RemoveRule(id)
}

func (h *Handler) AddRules(rules RuleRepository) {
	h.Rules = append(h.Rules, rules)
}

func (h *Handler) RemoveRule(id int) {
	h.Rules = append(h.Rules[:id], h.Rules[id + 1:]...)
}