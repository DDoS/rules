package inference_test

import (
	"testing"
	"io/ioutil"
	"encoding/json"
	"github.com/stretchr/testify/require"
	"github.com/michael-golfi/rules/server/inference"
	"bytes"
)

var (
	idTypeObj = []inference.Field{{Name: "id", Type: "string"}, {Name: "type", Type: "string"}}
	expected = []inference.Field{
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
		{Name: "ppu", Type: "float"},
		{Name: "ppu2", Type: "float"},
		{Name: "ppu3", Type: "int"},
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

	d := json.NewDecoder(bytes.NewReader(b))
	d.UseNumber()
	d.Decode(&data)

	require.NotNil(t, data, "Check the json file")

	actual := p.Parse(data)

	eq := p.FuzzyEqual(expected, actual)
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
	eq := p.FuzzyEqual(expected, expected)
	require.True(t, eq)
}

func TestParser_DeepEqual_False(t *testing.T) {
	p := inference.Parser{}
	eq := p.FuzzyEqual(expected, nil)
	require.False(t, eq)

	wrongName := make([]inference.Field, len(expected))
	copy(wrongName[:], expected)
	wrongName[0].Name = "WrongName"
	eq = p.FuzzyEqual(expected, wrongName)
	require.False(t, eq)

	nilSubObject := make([]inference.Field, len(expected))
	copy(nilSubObject[:], expected)
	nilSubObject[1].SubObject = nil
	eq = p.FuzzyEqual(expected, nilSubObject)
	require.False(t, eq)
}