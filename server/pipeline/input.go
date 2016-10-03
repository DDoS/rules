package pipeline

type PipeInput struct {
	Input chan interface{}
	Quit  chan bool
}

func CreateInput() *PipeInput {
	return &PipeInput{
		Input: make(chan interface{}),
		Quit: make(chan bool, 1),
	}
}
