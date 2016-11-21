package interpreter_test

import (
	"testing"
	"github.com/michael-golfi/rules/server/interpreter"
	"github.com/stretchr/testify/require"
	"net/http/httptest"
	"net/http"
	"encoding/json"
)

func TestNewHandler(t *testing.T) {
	host := "http://localhost:8080"
	path := "/api/v1/rules/default"

	handler, err := interpreter.NewHandler(host + path)
	require.Equal(t, "localhost:8080", handler.Uri.Host)
	require.Equal(t, path, handler.Uri.Path)
	require.NoError(t, err)
}

var (
	source =
		`def Numbers: {AnInt anInt, AFloat aFloat}

		def AnInt: {sint64 i}
		def AFloat: {fp32 f}

		when (Numbers numbers):
		return numbers.anInt.i != numbers.aFloat.f;

		then (Numbers numbers):
		return {anInt: {i: numbers.anInt.i + sint64(numbers.aFloat.f)}, aFloat: numbers.aFloat}`

	input = `{"anInt": {"i": 2}, "aFloat": {"f": 7.5}}`
)

func TestHandler_Evaluate(t *testing.T) {

	expected := `{
		"aFloat": {
			"f": 7.5
		},
		"anInt": {
			"i": 9
		}
	}`

	ts := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")

		var msg interpreter.Message
		err := json.NewDecoder(r.Body).Decode(&msg)
		require.NoError(t, err)

		require.Equal(t, source, msg.Source)
		require.Equal(t, input, msg.Input)

		w.Write([]byte(expected))
	}))

	defer ts.Close()

	handler, err := interpreter.NewHandler(ts.URL)
	require.NoError(t, err)

	resp, err := handler.Evaluate(source, input)
	require.NoError(t, err)

	require.Equal(t, expected, resp)
}