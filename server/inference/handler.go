package inference

type RuleParser interface {
	Parse([]byte) []Field
}

type SchemaParser interface {
	ParseSchema([]byte) []Field
}