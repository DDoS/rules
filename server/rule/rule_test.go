package rule_test

import (
	"testing"
	"github.com/michael-golfi/rules/server/rule"
	"github.com/ghodss/yaml"
	"encoding/json"
	"github.com/stretchr/testify/require"
)

const jsonRules = `
[
  {
    "id": 0,
    "when": "example 1",
    "then": "example 1"
  },
  {
    "id": 1,
    "when": "example 2",
    "then": "example 2"
  },
  {
    "id": 2,
    "when": "example 3",
    "then": "example 3"
  },
  {
    "id": 3,
    "when": "example 4",
    "then": "example 4"
  }
]
`

const yamlRules = `
- id: 0
  when: example 1
  then: example 1

- id: 1
  when: example 2
  then: example 2

- id: 2
  when: example 3
  then: example 3

- id: 3
  when: example 4
  then: example 4
  `

var rulesExpected = []rule.Rule{
	{
		Id: 0,
		When: "example 1",
		Then: "example 1",
	},
	{
		Id: 1,
		When: "example 2",
		Then: "example 2",
	},
	{
		Id: 2,
		When: "example 3",
		Then: "example 3",
	},
	{
		Id: 3,
		When: "example 4",
		Then: "example 4",
	},
}

func TestRule_YamlSerialize(t *testing.T) {
	byt, err := yaml.Marshal(&rulesExpected)
	require.NoError(t, err)
	yamlEqual(t, yamlRules, string(byt))
}

func TestRule_YamlDeserialize(t *testing.T) {
	var rules rule.RuleRepository
	err := yaml.Unmarshal([]byte(yamlRules), &rules)
	require.NoError(t, err)
	require.EqualValues(t, rulesExpected, rules)
}

func TestRule_JsonSerialize(t *testing.T) {
	byt, err := json.Marshal(&rulesExpected)
	require.NoError(t, err)
	yamlEqual(t, jsonRules, string(byt))
}

func TestRule_JsonDeserialize(t *testing.T) {
	var rules []rule.Rule
	err := yaml.Unmarshal([]byte(jsonRules), &rules)
	require.NoError(t, err)
	require.EqualValues(t, rulesExpected, rules)
}

func yamlEqual(t *testing.T, expected, actual string) {
	var expectedStruct interface{}
	err := yaml.Unmarshal([]byte(expected), &expectedStruct)
	require.NoError(t, err)

	var actualStruct interface{}
	err = yaml.Unmarshal([]byte(actual), &actualStruct)
	require.NoError(t, err)

	require.EqualValues(t, expectedStruct, actualStruct)
}

func TestRuleRepository_ToString(t *testing.T) {
	var rules rule.RuleRepository = make([]rule.Rule, 1)
	rules[0].Setup =
`def Numbers: {AnInt anInt, AFloat aFloat}

def AnInt: {sint64 i}
def AFloat: {fp32 f}`
	rules[0].When =
`when (Numbers numbers):
return numbers.anInt.i != numbers.aFloat.f;`

	rules[0].Then =
`then (Numbers numbers):
return {anInt: {i: numbers.anInt.i + sint64(numbers.aFloat.f)}, aFloat: numbers.aFloat}`

	expected :=
`def Numbers: {AnInt anInt, AFloat aFloat}

def AnInt: {sint64 i}
def AFloat: {fp32 f}

when (Numbers numbers):
return numbers.anInt.i != numbers.aFloat.f;

then (Numbers numbers):
return {anInt: {i: numbers.anInt.i + sint64(numbers.aFloat.f)}, aFloat: numbers.aFloat}`

	actual := rules.ToString()
	require.Equal(t, expected, actual)
}