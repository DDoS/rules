package yaml

import (
	"github.com/michael-golfi/rules/server/http/inference"
	"gopkg.in/yaml.v2"
	"github.com/michael-golfi/log4go"
)

func (y *YamlHandler) ParseYaml(schema []byte) []inference.Field {
	var in []inference.Field
	if err := yaml.Unmarshal(schema, &in); err != nil {
		log4go.Error(err)
	}

	return in
}
