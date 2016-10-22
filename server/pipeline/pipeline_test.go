package pipeline

import (
	"github.com/stretchr/testify/assert"
	"testing"
	"time"
)

func TestNewPipeline(t *testing.T) {
	in := CreateInput()
	p := NewPipeline("Default", nil, in)

	assert.NotNil(t, in)
	assert.NotNil(t, p)
	assert.Equal(t, STOPPED, p.State())
}

func TestPipeline_Start(t *testing.T) {
	in := CreateInput()
	p := NewPipeline("Default", nil, in)

	assert.NotNil(t, in)
	assert.NotNil(t, p)
	assert.Equal(t, STOPPED, p.State())

	p.Start(func(i interface{}) {})
	assert.Equal(t, RUNNING, p.State())
}

func TestPipeline_Stop(t *testing.T) {
	in := CreateInput()
	p := NewPipeline("Default", nil, in)

	assert.NotNil(t, in)
	assert.NotNil(t, p)
	assert.Equal(t, STOPPED, p.State())

	p.Start(func(i interface{}) {})
	assert.Equal(t, RUNNING, p.State())
	p.Stop()

	time.Sleep(1 * time.Second)
	assert.Equal(t, STOPPED, p.State())
}