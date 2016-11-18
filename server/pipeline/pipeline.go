package pipeline

import (
	"github.com/michael-golfi/log4go"
	"errors"
	"fmt"
	"github.com/michael-golfi/rules/server/pipeline/config"
)

type State int
const (
	RUNNING State = 1
	STOPPED State = 2
)

type Pipeline struct {
	state     State
	config    *config.Config
	pipeInput *PipeInput
}

func NewPipeline(config *config.Config, in *PipeInput) *Pipeline {
	return &Pipeline{
		config: config,
		state: STOPPED,
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



			case <-pipe.pipeInput.Quit:
				log4go.Info("Pipeline %s: Stopping", pipe.config.Name)
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

func (p *Pipeline) Config() *config.Config {
	return p.config
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