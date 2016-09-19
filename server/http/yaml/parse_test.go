package yaml

import (
	"testing"
	"github.com/davecgh/go-spew/spew"
)

const YAML_SAMPLE = `
- Name: id
  Type: string
- Name: type
  Type: string
- Name: name
  Type: string
- Name: ppu
  Type: double
- Name: batters
  Type: object
  SubObject:
  - Name: batter
    Type: array
    SubObject:
    - Name: '0'
      Type: object
      SubObject:
      - Name: id
        Type: string
      - Name: type
        Type: string
    - Name: '1'
      Type: object
      SubObject:
      - Name: id
        Type: string
      - Name: type
        Type: string
    - Name: '2'
      Type: object
      SubObject:
      - Name: type
        Type: string
      - Name: id
        Type: string
    - Name: '3'
      Type: object
      SubObject:
      - Name: id
        Type: string
        SubObject:
      - Name: type
        Type: string
- Name: topping
  Type: array
  SubObject:
  - Name: '0'
    Type: object
    SubObject:
    - Name: id
      Type: string
    - Name: type
      Type: string
  - Name: '1'
    Type: object
    SubObject:
    - Name: id
      Type: string
    - Name: type
      Type: string
  - Name: '2'
    Type: object
    SubObject:
    - Name: id
      Type: string
    - Name: type
      Type: string`

func TestYamlHandler_ParseYaml(t *testing.T) {
	y := YamlHandler{}
	fields := y.ParseYaml([]byte(YAML_SAMPLE))
	spew.Dump(fields)
}