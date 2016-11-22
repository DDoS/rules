package rule

import (
	"github.com/gorilla/mux"
	"net/http"
	"github.com/square/go-jose/json"
	"github.com/michael-golfi/log4go"
	"strconv"
	"fmt"
)

type Handler struct {
	Rules RuleRepository
}

func NewHandler() *Handler {
	return &Handler{
		Rules: RuleRepository{

		},
	}
}

func (h *Handler) SetRoutes(r *mux.Router) {
	r.HandleFunc("/rule", h.Add).Methods(http.MethodPost)
	r.HandleFunc("/rule/{id}", h.Delete).Methods(http.MethodDelete)
}

func (h *Handler) Add(w http.ResponseWriter, r *http.Request) {
	var rules RuleRepository

	if err := json.NewDecoder(r.Body).Decode(&rules); err != nil {
		message := fmt.Sprintf("Could not decode rule: %s", err.Error())

		log4go.Error(message)
		w.WriteHeader(http.StatusInternalServerError)
		w.Write([]byte(message))
		return
	}

	h.AddRules(rules)
}

func (h *Handler) Delete(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)

	id, err := strconv.Atoi(vars["id"])
	if err != nil {
		message := fmt.Sprintf("Could not decode rule id: %s", err.Error())

		log4go.Error(message)
		w.WriteHeader(http.StatusInternalServerError)
		w.Write([]byte(message))
		return
	}

	h.RemoveRule(id)
}

func (h *Handler) AddRules(rules RuleRepository) {
	h.Rules = append(h.Rules, rules...)
}

func (h *Handler) RemoveRule(id int) {
	for i, v := range h.Rules {
		if v.Id == id {
			h.Rules = append(h.Rules[:i], h.Rules[i + 1:]...)
		}
	}
}