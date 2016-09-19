package inference

import (
	"strconv"
	"encoding/json"
	"github.com/michael-golfi/log4go"
)

func ParseSchema(msg []byte) []Field {
	var obj interface{}

	if err := json.Unmarshal(msg, &obj); err != nil {
		log4go.Error(err)
	}

	fields, _ := GetType(obj)
	return fields
}

func GetType(in interface{}) ([]Field, string) {
	var jsonField []Field

	switch t := in.(type){

	case map[string]interface{}:
		for k, v := range t {
			sub, typeStr := GetType(v)
			field := Field{
				Name: k,
				Type: typeStr,
				SubObject: sub,
			}
			jsonField = append(jsonField, field)
		}
		return jsonField, "object"
	case []interface{}:
		for i, v := range t {
			sub, typeStr := GetType(v)
			field := Field{
				Name: strconv.Itoa(i),
				Type: typeStr,
				SubObject: sub,
			}
			jsonField = append(jsonField, field)
		}
		return jsonField, "array"
	case string:
		return nil, "string"
	case int:
		return nil, "int"
	case float32:
		return nil, "float32"
	case float64:
		return nil, "double"
	}

	return nil, ""
}