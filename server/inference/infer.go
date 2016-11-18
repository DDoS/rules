package inference

import (
	"strconv"
	"errors"
	"reflect"
	"github.com/michael-golfi/log4go"
)

type Field struct {
	Name      string `json: "Name"`
	Type      string `json: "Type"`
	SubObject []Field `json: "SubOject,omitempty"`
}

type Parser struct {

}

func (j *Parser) Parse(msg interface{}) []Field {
	if msg == nil {
		return nil
	}

	data, _ := parse(msg)
	return data
}

func (p *Parser) DeepEqual(expected, actual []Field) bool {
	if len(expected) != len(actual) {
		return false
	}

	for _, v := range expected {
		var dataVal *Field
		var err error
		if dataVal, err = whereKeyEquals(actual, v.Name); err != nil {
			log4go.Error("DeepEqual: Cannot find key")
			return false
		}

		if dataVal.Type == "array" || dataVal.Type == "object" {

			if !p.DeepEqual(v.SubObject, dataVal.SubObject) {
				log4go.Error("DeepEqual: !eq")
				return false
			}

		} else {
			if !reflect.DeepEqual(v, *dataVal) {
				log4go.Error("DeepEqual: Not equal")
				return false
			}
		}
	}

	return true
}

func whereKeyEquals(fields []Field, name string) (*Field, error) {
	for _, v := range fields {
		if v.Name == name {
			return &v, nil
		}
	}
	return nil, errors.New("Obj Not Found")
}

func parse(in interface{}) ([]Field, string) {
	var data []Field

	switch t := in.(type){

	case []interface{}:
		for i, v := range t {
			sub, typeStr := parse(v)
			field := Field{
				Name: strconv.Itoa(i),
				Type: typeStr,
				SubObject: sub,
			}
			data = append(data, field)
		}
		return data, "array"

	case map[string]interface{}:
		for k, v := range t {
			sub, typeStr := parse(v)
			field := Field{
				Name: k,
				Type: typeStr,
				SubObject: sub,
			}
			data = append(data, field)
		}
		return data, "object"

	case string:
		return nil, "string"
	case int:
		return nil, "number"
	case float32:
		return nil, "number"
	case float64:
		return nil, "number"
	}

	return nil, ""
}