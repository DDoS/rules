package api_test
import (
	"testing"
	"github.com/michael-golfi/rules/app/api"
	"github.com/stretchr/testify/assert"
)

type TestStruct struct {
	Name string
}

var (
	ingest = make(chan interface{})
	output = make(chan interface{})
	pipe *api.Pipeline
)

func TestMain(m *testing.M) {
	pipe = api.NewPipeline("Test", ingest, output)

	pipe.Run()
	m.Run()
}

func TestStart(t *testing.T) {
	assert.Equal(t, "Test", pipe.Name)
	assert.Equal(t, "NotStarted", pipe.CurrentState)

	pipe.Start()

	assert.Equal(t, "Test", pipe.Name)
	assert.Equal(t, "Running", pipe.CurrentState)
}

func TestDataProcessing(t *testing.T) {
	assert.Equal(t, "Test", pipe.Name)
	assert.Equal(t, "Running", pipe.CurrentState)

	ingest <- TestStruct{Name: "Test 1"}
	output1 := <- output
	test1 := output1.(TestStruct)
	assert.IsType(t, TestStruct{}, output1)
	assert.Equal(t, "Test 1", test1.Name)

	ingest <- TestStruct{Name: "Test 2"}
	output2 := <- output
	test2 := output2.(TestStruct)
	assert.IsType(t, TestStruct{}, output2)
	assert.Equal(t, "Test 2", test2.Name)

	ingest <- TestStruct{Name: "Test 3"}
	output3 := <- output
	test3 := output3.(TestStruct)
	assert.IsType(t, TestStruct{}, output3)
	assert.Equal(t, "Test 3", test3.Name)
}

func TestPauseAndStart(t *testing.T) {
	assert.Equal(t, "Test", pipe.Name)
	assert.Equal(t, "Running", pipe.CurrentState)

	pipe.Pause()
	assert.Equal(t, "Paused", pipe.CurrentState)

	pipe.Start()
	assert.Equal(t, "Running", pipe.CurrentState)
}

func TestStop(t *testing.T) {
	assert.Equal(t, "Test", pipe.Name)
	assert.Equal(t, "Running", pipe.CurrentState)

	pipe.Stop()
	assert.Equal(t, "Stopped", pipe.CurrentState)

	pipe.Start()
	assert.Equal(t, "Stopped", pipe.CurrentState)

	pipe.Pause()
	assert.Equal(t, "Stopped", pipe.CurrentState)
}