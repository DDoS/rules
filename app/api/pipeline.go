package api
import (
	"github.com/michael-golfi/log4go"
	"sync"
	"errors"
)

type Pipeline struct {
	Name         string
	CurrentState string

	Ingest       chan interface{}
	Output       chan interface{}

	Process      func(interface{}) interface{}

	Wait         *sync.WaitGroup

	StartChan    chan bool
	PauseChan    chan bool
	StopChan     chan bool
}

func NewPipeline(Name string, Input chan interface{}, Output chan interface{}) *Pipeline {
	return &Pipeline{
		Name: Name,

		Ingest: Input,
		Output: Output,

		Process: func(input interface{}) interface{} {
			return input
		},

		CurrentState: "NotStarted",
		Wait: &sync.WaitGroup{},

		StartChan: make(chan bool, 1),
		PauseChan: make(chan bool, 1),
		StopChan: make(chan bool, 1),
	}
}

func (pipe *Pipeline) Run() {
	go func(state *string, start, pause, stop chan bool, wait *sync.WaitGroup, input, output chan interface{}) {
		defer close(start)
		defer close(pause)
		defer close(stop)
		defer close(input)
		defer close(output)

		for {
			select {

			// Start the FSM
			case <-start:
				log4go.Info("Pipeline %s: Starting", pipe.Name)
				*state = "Running"
				wait.Done()

			// Start Processing Data
			case input := <-input:
				log4go.Info("Pipeline %s: Executing Process Input:%s", pipe.Name, input)
				output <- pipe.Process(input)

			// Pause the FSM
			case <-pause:
				log4go.Info("Pipeline %s: Pausing", pipe.Name)
				*state = "Paused"
				wait.Done()

			// Wait for Start signal
				<-start
				start <- true

			// Stop the FSM
			case <-stop:
				log4go.Info("Pipeline %s: Stopping", pipe.Name)
				*state = "Stopped"
				wait.Done()
				break
			}
		}
	}(&pipe.CurrentState, pipe.StartChan, pipe.PauseChan, pipe.StopChan, pipe.Wait, pipe.Ingest, pipe.Output)
}

func (pipe *Pipeline) Start() error {
	if pipe.CurrentState == "Running" {
		log4go.Info("Pipeline Already Running")
		return nil
	} else if pipe.CurrentState == "NotStarted" || pipe.CurrentState == "Paused" {
		pipe.Wait.Add(1)
		pipe.StartChan <- true
		pipe.Wait.Wait()
		return nil
	} else {
		log4go.Error("Tried to Start Pipeline from Invalid State: %s", pipe.CurrentState)
		return errors.New("Tried to Start Pipeline from Invalid State")
	}
}
func (pipe *Pipeline) Pause() error {
	if pipe.CurrentState == "Running" {
		pipe.Wait.Add(1)
		pipe.PauseChan <- true
		pipe.Wait.Wait()
		return nil
	} else {
		log4go.Error("Tried to Pause Pipeline from Invalid State: %s", pipe.CurrentState)
		return errors.New("Tried to Pause Pipeline from Invalid State")
	}
}
func (pipe *Pipeline) Stop() error {
	if pipe.StartChan != nil {
		pipe.Wait.Add(1)
		pipe.StopChan <- true
		pipe.Wait.Wait()
		return nil
	} else {
		log4go.Error("Tried to Stop Pipeline from Invalid State: %s", pipe.CurrentState)
		return errors.New("Tried to Stop Pipeline from Invalid State")
	}
}