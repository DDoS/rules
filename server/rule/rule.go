package rule

import (
	"fmt"
	"strings"
)

type RuleRepository []Rule

// Rules will have when-then structure.
// Rule execution should be decoupled.
// When a rule is executed, it won't have a link to the next rule.
// It will be applied to all the applicable rules.
// When and Then clauses will be P* code.
type Rule struct {
	Id    int `json:"id"`

	Setup string `json:"setup,omitempty"`

	When  string `json:"when"`
	Then  string `json:"then"`
}

// Build a rule file from a rule repository:
//
//Setup:
// def AnInt: {sint64 i}
// def AFloat: {fp32 f}
//When:
// when (Numbers numbers):
// return
//Then:
// then (Numbers numbers):
// return
func (r *RuleRepository) ToString() string {
	var s string
	for _, rule := range *r {
		ruleStr := fmt.Sprintf("%s\n%s\n%s", rule.Setup, rule.When, rule.Then)
		s += (ruleStr + "\n")
	}
	return strings.Trim(s, "\n")
}