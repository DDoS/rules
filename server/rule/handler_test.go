package rule_test

import (
	"testing"
	"github.com/michael-golfi/rules/server/rule"
	"github.com/stretchr/testify/require"
	"net/http"
	"net/http/httptest"
	"strings"
	"github.com/gorilla/mux"
)

var r = rule.RuleRepository{
	{
		Id: 0,
		When: "",
		Then: "",
	},
	{
		Id: 1,
		When: "",
		Then: "",
	},
	{
		Id: 2,
		When: "",
		Then: "",
	},
}

func TestHandler_Add(t *testing.T) {
	h := rule.NewHandler()

	rules := `[{"id": 0, "when": "Test", "then": "Http"}]`
	require.Len(t, h.Rules, 0)

	req, err := http.NewRequest("POST", "/rule", strings.NewReader(rules))
	if err != nil {
		t.Fatal(err)
	}

	rr := httptest.NewRecorder()
	handler := http.HandlerFunc(h.Add)
	handler.ServeHTTP(rr, req)

	require.Equal(t, http.StatusOK, rr.Code)

	require.Len(t, h.Rules, 1)
	require.Equal(t, h.Rules[0].When, "Test")
	require.Equal(t, h.Rules[0].Then, "Http")
}

func TestHandler_Add_Err(t *testing.T) {
	h := rule.NewHandler()

	rules := `[{ "id": "", "when": "", "then": "" }]`
	require.Len(t, h.Rules, 0)

	req, err := http.NewRequest(http.MethodPost, "/rule", strings.NewReader(rules))
	if err != nil {
		t.Fatal(err)
	}

	m := mux.NewRouter()
	h.SetRoutes(m)

	rr := httptest.NewRecorder()
	m.ServeHTTP(rr, req)

	require.Equal(t, http.StatusInternalServerError, rr.Code)
	require.Len(t, h.Rules, 0)
}

func TestHandler_Delete(t *testing.T) {
	h := rule.NewHandler()
	h.AddRules(rule.RuleRepository{
		{
			Id: 0,
			When: "",
			Then: "",
		},
	})

	require.Len(t, h.Rules, 1)

	req, err := http.NewRequest(http.MethodDelete, "/rule/0", nil)
	if err != nil {
		t.Fatal(err)
	}

	m := mux.NewRouter()
	h.SetRoutes(m)

	rr := httptest.NewRecorder()
	m.ServeHTTP(rr, req)

	require.Equal(t, http.StatusOK, rr.Code)
	require.Len(t, h.Rules, 0)
}

func TestHandler_Delete_ErrIdNaN(t *testing.T) {
	h := rule.NewHandler()
	h.AddRules(rule.RuleRepository{
		{
			Id: 0,
			When: "",
			Then: "",
		},
	})

	require.Len(t, h.Rules, 1)

	req, err := http.NewRequest(http.MethodDelete, "/rule/d", nil)
	if err != nil {
		t.Fatal(err)
	}

	m := mux.NewRouter()
	h.SetRoutes(m)

	rr := httptest.NewRecorder()
	m.ServeHTTP(rr, req)

	require.Equal(t, http.StatusInternalServerError, rr.Code)
	require.Len(t, h.Rules, 1)
}

func TestHandler_Delete_ErrIdEmpty(t *testing.T) {
	h := rule.NewHandler()
	h.AddRules(rule.RuleRepository{
		{
			Id: 0,
			When: "",
			Then: "",
		},
	})

	require.Len(t, h.Rules, 1)

	req, err := http.NewRequest(http.MethodDelete, "/rule/", nil)
	if err != nil {
		t.Fatal(err)
	}

	m := mux.NewRouter()
	h.SetRoutes(m)

	rr := httptest.NewRecorder()
	m.ServeHTTP(rr, req)

	require.Equal(t, http.StatusNotFound, rr.Code)
	require.Len(t, h.Rules, 1)
}

func TestHandler_AddRules(t *testing.T) {
	h := rule.NewHandler()
	require.Empty(t, h.Rules)

	h.AddRules(r)
	require.NotEmpty(t, h.Rules)
	require.Len(t, h.Rules, 3)
	require.EqualValues(t, h.Rules, r)
}

func TestHandler_RemoveRule(t *testing.T) {
	h := rule.NewHandler()
	require.Empty(t, h.Rules)
	h.AddRules(r)

	require.Len(t, h.Rules, 3)

	for i := 0; i < len(r) - 1; i++ {
		h.RemoveRule(i)
		require.Len(t, h.Rules, 2 - i)
	}
}