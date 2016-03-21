package api_test

import (
	"github.com/michael-golfi/rules/http/api"
	"github.com/stretchr/testify/assert"
	"testing"
)

type TestStruct struct {
	Name string
}

func TestDataInput(t *testing.T) {
	state := api.Default.Info()
	assert.Equal(t, api.UNSTARTED, state)

	dummyFunc := func(input interface{}) {}

	api.Default.Run(dummyFunc)

	state = api.Default.Info()
	assert.Equal(t, api.RUNNING, state)

	api.Default.Stop()

	state = api.Default.Info()
	assert.Equal(t, api.STOPPED, state)
}