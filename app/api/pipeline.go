package api

import (
	"github.com/michael-golfi/log4go"
	"sync"
)

type Pipeline struct {
	Name, state   string

	input, output chan interface{}

	process       func(interface{}) interface{}
	stop          chan bool
	wg            *sync.WaitGroup
}

func NewPipeline(name string, input chan interface{}, output chan interface{}, process func(input interface{}) interface{}) *Pipeline {
	return &Pipeline{
		Name: name,
		input: input,
		output: output,
		process:      process,
		stop:  make(chan bool, 1),
		wg: new(sync.WaitGroup),
	}
}

func (pipe *Pipeline) Run() {
	pipe.state = "Running"
	go func(pipe *Pipeline) {
		for {
			select {
			case input := <-pipe.input:
				log4go.Info("Pipeline %s: Executing Process Input:%s", pipe.Name, input)
				pipe.output <- pipe.process(input)

			case <-pipe.stop:
				log4go.Info("Pipeline %s: Stopping", pipe.Name)
				close(pipe.stop)
				return
			}
		}
	}(pipe)
}

func (pipe *Pipeline) Stop() {
	pipe.stop <- true
}