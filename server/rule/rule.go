package rule

type RuleRepository []Rule

// Rules will have when-then structure.
// Rule execution should be decoupled.
// When a rule is executed, it won't have a link to the next rule.
// It will be applied to all the applicable rules.
// When and Then clauses will be P* code.
type Rule struct {
	Id   int `json:"id"`

	When string `json:"when"`
	Then string `json:"then"`
}