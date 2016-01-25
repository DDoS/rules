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
	go func() {
		for {
			select {

			// Start the FSM
			case <-pipe.StartChan:
				log4go.Info("Pipeline %s: Starting", pipe.Name)
				pipe.CurrentState = "Running"
				pipe.Wait.Done()

			// Start Processing Data
			case input := <-pipe.Ingest:
				log4go.Info("Pipeline %s: Executing Process Input:%s", pipe.Name, input)
				pipe.Output <- pipe.Process(input)

			// Pause the FSM
			case <-pipe.PauseChan:
				log4go.Info("Pipeline %s: Pausing", pipe.Name)
				pipe.CurrentState = "Paused"
				pipe.Wait.Done()

				<-pipe.StartChan
				pipe.StartChan <- true

			// Stop the FSM
			case <-pipe.StopChan:
				log4go.Info("Pipeline %s: Stopping", pipe.Name)
				pipe.CurrentState = "Stopped"
				pipe.Wait.Done()
				break
			}
		}
		close(pipe.Ingest)
		close(pipe.Output)
		close(pipe.StartChan)
		close(pipe.PauseChan)
		close(pipe.StopChan)
	}()
}

func (pipe *Pipeline) Start() error {
	if pipe.CurrentState == "NotStarted" || pipe.CurrentState == "Paused" {
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