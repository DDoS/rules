package pipeline

import (
	"github.com/michael-golfi/log4go"
	"errors"
	"sync"
	"github.com/gorilla/mux"
)

const (
	UNSTARTED = 0
	RUNNING = 1
	STOPPED = 2
)

type Pipeline struct {
	Name    string
	state   int
	input   chan interface{}
	process func(interface{})
	stop    chan bool
}

var (
	Default = NewPipeline("Default")
	wait sync.WaitGroup
)

func NewPipeline(name string) *Pipeline {
	return &Pipeline{
		Name: name,
		state: UNSTARTED,
		input: make(chan interface{}, 10),
		stop:  make(chan bool, 1),
	}
}

func (pipe *Pipeline) Run(processer func(input interface{})) {
	pipe.state = RUNNING
	pipe.process = processer

	go func(pipe *Pipeline) {
		for {
			select {
			case input := <-pipe.input:
				pipe.process(input)

			case <-pipe.stop:
				log4go.Info("Pipeline %s: Stopping", pipe.Name)
				pipe.state = STOPPED
				wait.Done()
				return
			}
		}
	}(pipe)
}

func (pipe *Pipeline) Input(input interface{}) error {
	if pipe.state == RUNNING {
		pipe.input <- input
		return nil
	} else {
		return errors.New("Cannot use Pipeline, it isn't running")
	}
}

func (pipe *Pipeline) Info() int {
	return pipe.state
}

func (pipe *Pipeline) Stop() error {
	if pipe.state == RUNNING {
		wait.Add(1)
		pipe.stop <- true
		wait.Wait()
		return nil
	} else {
		return errors.New("Pipe is already stopped")
	}
}