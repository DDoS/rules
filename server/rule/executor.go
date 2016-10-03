package rule

type Executor interface {
	Execute(args []interface{}) (Executor, interface{})
}