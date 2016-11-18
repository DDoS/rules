package pipeline

import (
	"github.com/stretchr/testify/assert"
	"testing"
	"time"
	"github.com/michael-golfi/rules/server/pipeline/config"
	"github.com/michael-golfi/rules/server/rule"
	"github.com/michael-golfi/rules/server/inference"
)

var conf = config.Config{
	Name: "Default",
	Schema: []inference.Field{},
	Rules: rule.RuleRepository{},
}

func TestNewPipeline(t *testing.T) {
	in := CreateInput()
	p := NewPipeline(&conf, in)

	assert.NotNil(t, in)
	assert.NotNil(t, p)
	assert.Equal(t, STOPPED, p.State())
}

func TestPipeline_Start(t *testing.T) {
	in := CreateInput()
	p := NewPipeline(&conf, in)

	assert.NotNil(t, in)
	assert.NotNil(t, p)
	assert.Equal(t, STOPPED, p.State())

	p.Start()
	assert.Equal(t, RUNNING, p.State())
}

func TestPipeline_Stop(t *testing.T) {
	in := CreateInput()
	p := NewPipeline(&conf, in)

	assert.NotNil(t, in)
	assert.NotNil(t, p)
	assert.Equal(t, STOPPED, p.State())

	p.Start()
	assert.Equal(t, RUNNING, p.State())
	p.Stop()

	time.Sleep(1 * time.Second)
	assert.Equal(t, STOPPED, p.State())
}