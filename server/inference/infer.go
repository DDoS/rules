package inference

import (
	"strconv"
	"errors"
	"github.com/michael-golfi/log4go"
	"reflect"
	"encoding/json"
)

type Field struct {
	Name      string `json: "Name"`
	Type      string `json: "Type"`
	SubObject []Field `json: "SubOject,omitempty"`
}

type Parser struct {

}

func (j *Parser) Parse(msg interface{}) []Field {
	data, _ := parse(msg)
	return data
}

func (p *Parser) FuzzyEqual(expected, actual []Field) bool {
	for _, exp := range expected {
		var actualVal Field
		var err error
		actualVal, err = whereKeyEquals(actual, exp.Name)
		if err != nil {
			log4go.Error("FuzzyEqual: Cannot find key: %s", exp.Name)
			return false
		}

		if actualVal.Type == "array" || actualVal.Type == "object" {

			if !p.FuzzyEqual(exp.SubObject, actualVal.SubObject) {
				log4go.Error("FuzzyEqual: !eq")
				return false
			}

		} else {

			if exp.Type == "float" && actualVal.Type == "int" {
				continue;
			}

			if !reflect.DeepEqual(exp, actualVal) {
				log4go.Error("DeepEqual: Not equal")
				return false
			}

		}
	}

	return true
}

func whereKeyEquals(fields []Field, name string) (Field, error) {
	for i := range fields {
		if fields[i].Name == name {
			return fields[i], nil
		}
	}
	return Field{}, errors.New("Obj Not Found")
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
	case json.Number:

		if _, err := t.Int64(); err == nil {
			return nil, "int"
		} else if _, err := t.Float64(); err == nil {
			return nil, "float"
		}
	}

	return nil, ""
}