package api_test

import (
	"github.com/michael-golfi/rules/app/api"
	"github.com/stretchr/testify/assert"
	"testing"
	"fmt"
)

type TestStruct struct {
	Name string
}

func processData(pipe *api.Pipeline, t *testing.T) {
	j := 100
	for i := 0; i < j; i++ {
		pipe.Input(TestStruct{Name: fmt.Sprintf("Test %d", i)})
		output1 := <-pipe.Output
		test := output1.(TestStruct)
		assert.IsType(t, TestStruct{}, output1)
		assert.Equal(t, fmt.Sprintf("Test %d", i), test.Name)
	}
}

func TestDataProcessing(t *testing.T) {
	ingest := make(chan interface{})
	output := make(chan interface{})
	passthrough := func(input interface{}) interface{} {
		return input
	}
	pipe := api.NewPipelineChan("Test", ingest, output, passthrough)
	pipe.Run()

	assert.Equal(t, "Test", pipe.Name)
	defer pipe.Stop()

	processData(pipe, t)
}

func TestPipeNotRunning(t *testing.T) {
	ingest := make(chan interface{})
	output := make(chan interface{})
	passthrough := func(input interface{}) interface{} {
		return input
	}
	pipe := api.NewPipelineChan("Test", ingest, output, passthrough)

	assert.Equal(t, "Test", pipe.Name)
	defer pipe.Stop()

	err := pipe.Input(TestStruct{Name: "Test"})
	assert.Error(t, err)
}