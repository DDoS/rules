package rule

type Conditional struct {
	Rule

	Predicate func(args []interface{}) bool

	True      Executor
	False     Executor
}

func (c Conditional) Execute(args []interface{}) (Executor, interface{}) {
	if c.Predicate(args) {
		return c.True, true
	}
	return c.False, false
}