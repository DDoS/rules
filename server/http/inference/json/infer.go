package inference

import (
	"strconv"
	"encoding/json"
	"github.com/michael-golfi/log4go"
	"github.com/michael-golfi/rules/server/http/inference"
)

func (j *JsonHandler) Parse(msg []byte) []inference.Field {
	var obj interface{}

	if err := json.Unmarshal(msg, &obj); err != nil {
		log4go.Error(err)
	}

	data, _ := parse(obj)
	return data
}

func parse(in interface{}) ([]inference.Field, string) {
	var data []inference.Field

	switch t := in.(type){

	case map[string]interface{}:
		for k, v := range t {
			sub, typeStr := parse(v)
			field := inference.Field{
				Name: k,
				Type: typeStr,
				SubObject: sub,
			}
			data = append(data, field)
		}
		return data, "object"
	case []interface{}:
		for i, v := range t {
			sub, typeStr := parse(v)
			field := inference.Field{
				Name: strconv.Itoa(i),
				Type: typeStr,
				SubObject: sub,
			}
			data = append(data, field)
		}
		return data, "array"
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