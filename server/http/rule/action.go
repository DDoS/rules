package rule

type Action struct {
	Rule

	NextRule Rule
}

func (a *Action) Execute() {

}