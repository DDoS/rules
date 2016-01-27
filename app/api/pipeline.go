package api

import (
	"github.com/michael-golfi/log4go"
	"sync"
	"errors"
)

type Pipeline struct {
	Name, state   string

	input, Output chan interface{}

	process       func(interface{}) interface{}
	stop          chan bool
	wg            *sync.WaitGroup
}

func NewPipeline(name string, input chan interface{}, output chan interface{}, process func(input interface{}) interface{}) *Pipeline {
	return &Pipeline{
		Name: name,
		input: input,
		Output: output,
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
				pipe.Output <- pipe.process(input)

			case <-pipe.stop:
				log4go.Info("Pipeline %s: Stopping", pipe.Name)
				close(pipe.stop)
				return
			}
		}
	}(pipe)
}

func (pipe *Pipeline) Input(input interface{}) error {
	if pipe.state == "Running" {
		pipe.input <- input
		return nil
	} else {
		return errors.New("Cannot use Pipeline, it isn't running")
	}
}

func (pipe *Pipeline) Stop() error {
	if pipe.state == "Running" {
		pipe.stop <- true
		return nil
	} else {
		return errors.New("Pipe is already stopped")
	}
}