package inference

import (
	"testing"
	"github.com/stretchr/testify/assert"
	"github.com/michael-golfi/rules/server/inference"
	"github.com/go-errors/errors"
	"io/ioutil"
)

func TestInferJsonStructure(t *testing.T) {
	j := JsonHandler{}

	b, err := ioutil.ReadFile("./sample.json")
	assert.NoError(t, err)
	data := j.Parse(b)

	idTypeObj := []inference.Field{{Name: "id", Type: "string"}, {Name: "type", Type: "string"}}
	val := []inference.Field{
		{Name: "id", Type: "string"},
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
		{Name: "ppu", Type: "double"},
		{
			Name: "topping", Type: "array",
			SubObject: []inference.Field{{Name: "0", Type: "object", SubObject: idTypeObj}},
		},
		{Name: "type", Type: "string"},
	}

	assertDeepValues(t, val, data)
}

func assertDeepValues(t *testing.T, expected, actual []inference.Field) {
	for _, v := range expected {
		dataVal, err := whereKeyEquals(actual, v.Name)

		if err != nil {
			assert.FailNow(t, err.Error())
		}

		if dataVal.Type == "array" || dataVal.Type == "object" {
			assertDeepValues(t, v.SubObject, dataVal.SubObject)
		} else {
			assert.EqualValues(t, v, *dataVal)
		}
	}
}

func whereKeyEquals(fields []inference.Field, name string) (*inference.Field, error) {
	for _, v := range fields {
		if v.Name == name {
			return &v, nil
		}
	}
	return nil, errors.New("Obj Not Found")
}