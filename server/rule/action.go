package rule

type Action struct {
	Rule

	Func     func(args []interface{}) interface{}

	NextRule Executor
}

func (a Action) Execute(args []interface{}) (Executor, interface{}) {
	return a.NextRule, a.Func(args)
}