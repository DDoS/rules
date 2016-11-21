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

	client, err := interpreter.NewHandler("127.0.0.1:9090/api/v1/rules/default")
	if err != nil {
		log4go.Error("Couldn't connect to interpreter... %s", err.Error())
		return err
	}

	go func(pipe *Pipeline, client *interpreter.Handler) {

		for {
			select {
			case input := <-pipe.pipeInput.Input:



				source := pipe.config.Rules.ToString()
				b, err := json.Marshal(input)

				if err != nil {
					log4go.Error("Could not serialize input: %s", err.Error())
				}

				resp, err := client.Evaluate(source, string(b))
				if err != nil {
					log4go.Error("Cannot execute rule: %s", err.Error())
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