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

var (
	ingest = make(chan interface{})
	output = make(chan interface{})
	pipe   *api.Pipeline
)

func TestMain(m *testing.M) {
	passthrough := func(input interface{}) interface{} {
		return input
	}
	pipe = api.NewPipeline("Test", ingest, output, passthrough)
	pipe.Run()
	m.Run()
}

func TestDataProcessing(t *testing.T) {
	assert.Equal(t, "Test", pipe.Name)
	defer pipe.Stop()
	for i := 0; i < 100; i++ {
		ingest <- TestStruct{Name: fmt.Sprintf("Test %d", i)}
		output1 := <-output
		test := output1.(TestStruct)
		assert.IsType(t, TestStruct{}, output1)
		assert.Equal(t, fmt.Sprintf("Test %d", i), test.Name)
	}
}