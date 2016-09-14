package rule

type Conditional struct {
	Rule

	True  Rule
	False Rule
}

func (c *Conditional) Execute() {

}