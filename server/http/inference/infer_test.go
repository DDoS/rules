package inference

import (
	"testing"
	"fmt"
	"encoding/json"
	"github.com/davecgh/go-spew/spew"
)

func TestInferJsonStructure(t *testing.T) {
	b := []byte(`
{
	"id": "0001",
	"type": "donut",
	"name": "Cake",
	"ppu": 0.55,
	"batters":
		{
			"batter":
				[
					{ "id": "1001", "type": "Regular" },
					{ "id": "1002", "type": "Chocolate" },
					{ "id": "1003", "type": "Blueberry" },
					{ "id": "1004", "type": "Devil's Food" }
				]
		},
	"topping":
		[
			{ "id": "5001", "type": "None" },
			{ "id": "5002", "type": "Glazed" },
			{ "id": "5004", "type": "Maple" }
		]
}
	`)

	data := ParseSchema(b)
	fmt.Printf("%+v\n", data)
}

func TestGetType(t *testing.T) {
	b := []byte(`
{
	"id": "0001",
	"type": "donut",
	"name": "Cake",
	"ppu": 0.55,
	"batters":
		{
			"batter":
				[
					{ "id": "1001", "type": "Regular" },
					{ "id": "1002", "type": "Chocolate" },
					{ "id": "1003", "type": "Blueberry" },
					{ "id": "1004", "type": "Devil's Food" }
				]
		},
	"topping":
		[
			{ "id": "5001", "type": "None" },
			{ "id": "5002", "type": "Glazed" },
			{ "id": "5004", "type": "Maple" }
		]
}
	`)

	var obj interface{}
	json.Unmarshal(b, &obj)
	fields, typeStr := GetType(obj)
	fmt.Println(typeStr)
	spew.Dump(fields)
}