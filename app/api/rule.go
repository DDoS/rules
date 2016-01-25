package api

// Prototype for a rule structure
type Rule struct {
	Name        string `json:"name" yaml:"name"`
	Description string `json:"description" yaml:"description"`
	Priority    int    `json:"priority" yaml:"priority"`
}
