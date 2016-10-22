package process

import (
	"testing"
	"encoding/json"
	"bytes"
	"github.com/stretchr/testify/assert"
)

func TestProcessDecode(t *testing.T) {
	process := new(Process)
	err := json.NewDecoder(bytes.NewReader(msg)).Decode(process)
	assert.NoError(t, err)

	assert.Len(t, process.Operators, 7)
	assert.Len(t, process.Links, 6)

	hasStart := false
	numEnds := 0
	hasIf := false
	hasSwitch := false

	for _, v := range process.Operators {
		if v.Properties.Title == "Start" {
			hasStart = true
		}

		if v.Properties.Title == "End" {
			numEnds++
		}

		if v.Properties.Title == "If" {
			hasIf = true
		}

		if v.Properties.Title == "Switch" {
			hasSwitch = true
		}
	}

	assert.True(t, hasStart)
	assert.Equal(t, numEnds, 4)
	assert.True(t, hasIf)
	assert.True(t, hasSwitch)
}

var msg = []byte(`
{
  "operators": [
    {
      "properties": {
        "title": "Start",
        "outputs": [
          {
            "label": ""
          }
        ],
        "inputs": [

        ]
      }
    },
    {
      "properties": {
        "title": "If",
        "inputs": [
          {
            "label": "In"
          }
        ],
        "outputs": [
          {
            "label": "true"
          },
          {
            "label": "false"
          }
        ]
      }
    },
    {
      "properties": {
        "title": "Switch",
        "inputs": [
          {
            "label": "In"
          }
        ],
        "outputs": [
          {
            "label": "Case 1"
          },
          {
            "label": "Case 2"
          },
          {
            "label": "Case 3"
          }
        ]
      }
    },
    {
      "properties": {
        "title": "End",
        "inputs": [
          {
            "label": ""
          }
        ],
        "outputs": [

        ]
      }
    },
    {
      "properties": {
        "title": "End",
        "inputs": [
          {
            "label": ""
          }
        ],
        "outputs": [

        ]
      }
    },
    {
      "properties": {
        "title": "End",
        "inputs": [
          {
            "label": ""
          }
        ],
        "outputs": [

        ]
      }
    },
    {
      "properties": {
        "title": "End",
        "inputs": [
          {
            "label": ""
          }
        ],
        "outputs": [

        ]
      }
    }
  ],
  "links": [
    {
      "fromOperator": 0,
      "fromConnector": "Out",
      "fromSubConnector": 0,
      "toOperator": 1,
      "toConnector": "Input",
      "toSubConnector": 0
    },
    {
      "fromOperator": 1,
      "fromConnector": "true",
      "fromSubConnector": 0,
      "toOperator": 2,
      "toConnector": "Input",
      "toSubConnector": 0
    },
    {
      "fromOperator": 2,
      "fromConnector": "Case 3",
      "fromSubConnector": 0,
      "toOperator": 3,
      "toConnector": "In",
      "toSubConnector": 0
    },
    {
      "fromOperator": 2,
      "fromConnector": "Case 2",
      "fromSubConnector": 0,
      "toOperator": 4,
      "toConnector": "In",
      "toSubConnector": 0
    },
    {
      "fromOperator": 1,
      "fromConnector": "false",
      "fromSubConnector": 0,
      "toOperator": 5,
      "toConnector": "In",
      "toSubConnector": 0
    },
    {
      "fromOperator": 2,
      "fromConnector": "Case 1",
      "fromSubConnector": 0,
      "toOperator": 6,
      "toConnector": "In",
      "toSubConnector": 0
    }
  ],
  "operatorTypes": {

  }
}
	`)