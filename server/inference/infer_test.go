package inference_test

import (
	"testing"
	"io/ioutil"
	"encoding/json"
	"github.com/stretchr/testify/require"
	"github.com/michael-golfi/rules/server/inference"
)

var (
	idTypeObj = []inference.Field{{Name: "id", Type: "string"}, {Name: "type", Type: "string"}}
	val = []inference.Field{
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
		{Name: "ppu", Type: "number"},
		{
			Name: "topping", Type: "array",
			SubObject: []inference.Field{{Name: "0", Type: "object", SubObject: idTypeObj}},
		},
		{Name: "type", Type: "string"},
	}
)

func TestParser_Parse(t *testing.T) {
	p := inference.Parser{}

	b, err := ioutil.ReadFile("./sample.json")
	require.NoError(t, err)

	var data interface{}
	err = json.Unmarshal(b, &data)
	fields := p.Parse(data)

	eq := p.DeepEqual(val, fields)
	require.True(t, eq)
}

func TestParser_Parse_Single(t *testing.T) {
	p := inference.Parser{}

	idTypeJson := `{"id":"1001","type":"regular"}`

	var data interface{}
	err := json.Unmarshal([]byte(idTypeJson), &data)
	require.NoError(t, err)
	fields := p.Parse(data)

	require.NotEmpty(t, fields)
	require.EqualValues(t, idTypeObj, fields)

	idTypeJson = `{"id":"1001"}`
	err = json.Unmarshal([]byte(idTypeJson), &data)
	require.NoError(t, err)
	fields = p.Parse(data)

	require.NotEmpty(t, fields)
	require.EqualValues(t, []inference.Field{{Name: "id", Type: "string" } }, fields)
}

func TestParser_Parse_Err(t *testing.T) {
	p := inference.Parser{}

	var data interface{}
	fields := p.Parse(data)
	require.Nil(t, fields)
}

func TestParser_DeepEqual_True(t *testing.T) {
	p := inference.Parser{}
	eq := p.DeepEqual(val, val)
	require.True(t, eq)
}

func TestParser_DeepEqual_False(t *testing.T) {
	p := inference.Parser{}
	eq := p.DeepEqual(val, nil)
	require.False(t, eq)

	wrongName := make([]inference.Field, len(val))
	copy(wrongName[:], val)
	wrongName[0].Name = "WrongName"
	eq = p.DeepEqual(val, wrongName)
	require.False(t, eq)

	nilSubObject := make([]inference.Field, len(val))
	copy(nilSubObject[:], val)
	nilSubObject[1].SubObject = nil
	eq = p.DeepEqual(val, nilSubObject)
	require.False(t, eq)
}