package main_test

import (
	"testing"
	"net/http"
	"github.com/michael-golfi/go-http-utils"
	"github.com/stretchr/testify/assert"
	"github.com/michael-golfi/rules/http/api"
	"strings"
)

func TestMain(m *testing.M) {
	router := util.NewRouter(api.Routes)
	go http.ListenAndServe(":8080", router)

	m.Run()
}

func TestHealth(t *testing.T) {
	api.Default = api.NewPipeline("Default")

	resp, err := http.Get("http://localhost:8080/health")
	assert.Equal(t, resp.StatusCode, http.StatusNotModified)
	assert.NoError(t, err)

	api.Default.Run(func(input interface{}) {})
	resp, err = http.Get("http://localhost:8080/health")
	assert.Equal(t, resp.StatusCode, http.StatusOK)
	assert.NoError(t, err)

	api.Default.Stop()
	resp, err = http.Get("http://localhost:8080/health")
	assert.Equal(t, resp.StatusCode, http.StatusServiceUnavailable)
	assert.NoError(t, err)
}

func TestDataInput(t *testing.T) {
	api.Default = api.NewPipeline("Default")
	api.Default.Run(func(input interface{}) {})

	_, err := http.Post("http://localhost:8080/", "text/json", strings.NewReader(""))
	assert.NoError(t, err)
}