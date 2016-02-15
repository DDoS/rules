package api_test

import (
	"testing"
	"github.com/michael-golfi/rules/app/api"
	"github.com/stretchr/testify/assert"
	"sync"
	"fmt"
)

func TestCreateEngine(t *testing.T) {
	engine := api.GetEngine()

	input := make(chan interface{})
	output := make(chan interface{})
	process := func(input interface{}) interface{} {
		return input
	}

	pipe := api.NewPipelineChan("Pipe", input, output, process)
	pipe.Run()

	engine.Save(pipe)
	assert.Equal(t, 1, engine.CountPipes())

	wg := new(sync.WaitGroup)
	for i := 0; i < 10; i++ {
		wg.Add(1)
		go func(pipe *api.Pipeline, t *testing.T, wg *sync.WaitGroup) {
			processData(pipe, t)
			wg.Done()
		}(pipe, t, wg)
	}

	wg.Wait()

	engine.Delete(pipe.Name)
	assert.Equal(t, 0, engine.CountPipes())
}

func TestCreatePipelineParallel(t *testing.T) {
	engine := api.GetEngine()

	input := make(chan interface{})
	output := make(chan interface{})
	process := func(input interface{}) interface{} {
		return input
	}

	j := 10000
	wg := new (sync.WaitGroup)
	wg.Add(j)

	for i := 0; i < j; i++ {
		go func(engine *api.Engine, wg *sync.WaitGroup, i int) {
			name := fmt.Sprintf("Pipe %d", i)
			pipe := api.NewPipelineChan(name, input, output, process)
			pipe.Run()
			engine.Save(pipe)
			wg.Done()
		}(engine, wg, i)
	}

	wg.Wait()
	assert.Equal(t, j, engine.CountPipes())

	for i := 0; i < j; i++ {
		wg.Add(1)
		go func(engine *api.Engine, wg *sync.WaitGroup, i int) {
			name := fmt.Sprintf("Pipe %d", i)
			engine.Delete(name)
			wg.Done()
		}(engine, wg, i)
	}
	wg.Wait()
	assert.Equal(t, 0, engine.CountPipes())
}