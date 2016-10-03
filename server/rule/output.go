package rule

type Output struct {
	Rule

	Func func(args []interface{})
}

func (o Output) Execute(args []interface{}) (Executor, interface{}) {
	o.Func(args)
	return nil, nil
}