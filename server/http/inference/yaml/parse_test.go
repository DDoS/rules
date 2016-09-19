package yaml

import (
	"testing"
	"github.com/stretchr/testify/assert"
	"github.com/michael-golfi/rules/server/http/inference"
	"io/ioutil"
)

func TestYamlHandler_ParseYaml(t *testing.T) {
	y := YamlHandler{}

	b, err := ioutil.ReadFile("./sample.yaml")
	assert.NoError(t, err)
	
	data := y.ParseSchema(b)

	idTypeObj := []inference.Field{{Name: "id", Type: "string"}, {Name: "type", Type: "string"}}
	val := []inference.Field{
		{Name: "id", Type: "string"},
		{Name: "type", Type: "string"},
		{Name: "ppu", Type: "double"},
		{
			Name: "batters", Type: "object",
			SubObject: []inference.Field{
				{
					Name: "batter",
					Type: "array",
					SubObject: []inference.Field{
						{Name: "0", Type: "object", SubObject: idTypeObj},
						{Name: "1", Type: "object", SubObject: idTypeObj},
					},
				},

			},
		},
		{
			Name: "topping", Type: "array",
			SubObject: []inference.Field{{Name: "0", Type: "object", SubObject: idTypeObj}},
		},
	}

	assert.EqualValues(t, val, data)
}