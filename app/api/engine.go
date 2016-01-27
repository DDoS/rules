package api

import (
	"github.com/streamrail/concurrent-map"
)

type Engine struct {
	pipelines cmap.ConcurrentMap
}

var (
	engine = &Engine{
		pipelines: cmap.New(),
	}
)

func GetEngine() *Engine {
	return engine
}

func (en *Engine) EvaluateData(pipelineName string, data interface{}) {
	if tmp, ok := en.pipelines.Get(pipelineName); ok {
		pipe := tmp.(*Pipeline)
		pipe.Input(data)
	}
}

func (en *Engine) Save(pipe *Pipeline) {
	en.pipelines.Set(pipe.Name, pipe)
}

func (en *Engine) Delete(name string) {
	en.pipelines.Remove(name)
}

func (en *Engine) CountPipes() int {
	return en.pipelines.Count()
}