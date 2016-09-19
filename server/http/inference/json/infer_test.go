package inference

import (
	"testing"
	"github.com/stretchr/testify/assert"
	"github.com/michael-golfi/rules/server/http/inference"
	"github.com/go-errors/errors"
)

func TestInferJsonStructure(t *testing.T) {
	b := []byte(`
{
	"id": "0001",
	"type": "donut",
	"ppu": 0.55,
	"batters": {
			"batter":[
				{ "id": "1001", "type": "Regular" },
				{ "id": "1002", "type": "Chocolate" }
			]
		},
	"topping": [
		{ "id": "5001", "type": "None" }
	]
}
	`)

	data := ParseSchema(b)

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

	for _, v := range val {
		dataVal, err := whereKeyEquals(data, v.Name)
		if err != nil {
			assert.FailNow(t, err.Error())
		}
		assert.EqualValues(t, v, *dataVal)
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