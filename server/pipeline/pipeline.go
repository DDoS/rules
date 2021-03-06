package pipeline

import (
	"github.com/michael-golfi/log4go"
	"errors"
	"github.com/michael-golfi/rules/server/pipeline/config"
	"github.com/michael-golfi/rules/server/interpreter"
	"encoding/json"
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

func NewPipeline(config *config.Config, client *interpreter.Handler) *Pipeline {
	client.AddRule(config.Name, config.Rules.ToString())

	return &Pipeline{
		config: config,
		state: STOPPED,
		pipeInput: CreateInput(),
	}
}

func (p *Pipeline) Start(client *interpreter.Handler) error {
	if p.State() == RUNNING {
		return errors.New("Pipeline is already running")
	}

	p.state = RUNNING

	go func(pipe *Pipeline, client *interpreter.Handler) {

		for {
			select {
			case input := <-pipe.pipeInput.Input:
				b, err := json.Marshal(input)

				if err != nil {
					log4go.Error("Could not serialize input: %s", err.Error())
					continue
				}

				log4go.Debug("Evaluating: %s", string(b))
				resp, err := client.Evaluate(pipe.config.Name, string(b))
				if err != nil {
					log4go.Error("Cannot execute rule: %s", err.Error())
					continue
				}

				log4go.Info("Response: %s", resp)

			case <-pipe.pipeInput.Quit:
				log4go.Info("Pipeline %s: Stopping", pipe.config.Name)
				pipe.state = STOPPED
				return
			}
		}
	}(p, client)

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