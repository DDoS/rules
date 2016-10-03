package pipeline

import (
	"github.com/michael-golfi/log4go"
	"errors"
)

type Pipeline struct {
	Name      string
	state     State
	pipeInput *PipeInput
	process   func(interface{})
}

func NewPipeline(name string, in *PipeInput) *Pipeline {
	return &Pipeline{
		Name: name,
		state: STOPPED,
		pipeInput: in,
	}
}

func (p *Pipeline) Start(processer func(input interface{})) error {
	if p.State() == RUNNING {
		return errors.New("Pipeline is already running")
	}

	p.state = RUNNING
	p.process = processer

	go func(pipe *Pipeline) {
		for {
			select {
			case input := <-pipe.pipeInput.Input:
				pipe.process(input)

			case <-pipe.pipeInput.Quit:
				log4go.Info("Pipeline %s: Stopping", pipe.Name)
				pipe.state = STOPPED
				return
			}
		}
	}(p)

	return nil
}

func (p *Pipeline) Input(input interface{}) error {
	if p.state == RUNNING {
		p.pipeInput.Input <- input
		return nil
	} else {
		return errors.New("Pipeline is not running")
	}
}

func (p *Pipeline) State() State {
	return p.state
}

func (p *Pipeline) Stop() error {
	if p.state == STOPPED {
		return errors.New("Pipe is stopped")
	}

	p.pipeInput.Quit <- true
	return nil
}