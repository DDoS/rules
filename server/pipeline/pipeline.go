package pipeline

import (
	"github.com/michael-golfi/log4go"
	"errors"
	"github.com/michael-golfi/rules/server/pipeline/process"
	"fmt"
)

type Pipeline struct {
	Name      string
	state     State
	pipeInput *PipeInput
	process   *process.Process
}

func NewPipeline(name string, process *process.Process, in *PipeInput) *Pipeline {
	return &Pipeline{
		Name: name,
		state: STOPPED,
		process: process,
		pipeInput: in,
	}
}

func (p *Pipeline) Start() error {
	if p.State() == RUNNING {
		return errors.New("Pipeline is already running")
	}

	p.state = RUNNING

	go func(pipe *Pipeline) {
		for {
			select {
			case input := <-pipe.pipeInput.Input:
				fmt.Println(input)
			//pipe.process(input)

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