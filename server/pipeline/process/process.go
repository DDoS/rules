package process

type Process struct {
	Operators []Operator `json:"operators,omitempty"`
	Links     []Link `json:"links,omitempty"`
}

type Label struct {
	Name string `json:"label,omitempty"`
}

type Operator struct {
	Properties OperatorProperties `json:"properties"`
}

type OperatorProperties struct {
	Title   string `json:"title,omitempty"`
	Inputs  []Label `json:"inputs,omitempty"`
	Outputs []Label `json:"outputs,omitempty"`
}

type Link struct {
	FromOperator     int `json:"fromOperator,omitempty"`
	FromConnector    string `json:"ffomConnector,omitempty"`
	FromSubConnector int `json:"fromSubConnector,omitempty"`

	ToOperator       int `json:"toOperator,omitempty"`
	ToConnector      string `json:"toConnector,omitempty"`
	ToSubConnector   int `json:"toSubConnector,omitempty"`
}