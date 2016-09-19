package inference

type Field struct {
	Name      string `json: "Name" yaml:"Name"`
	Type      string `json: "Type" yaml:"Type"`
	SubObject []Field `json: "SubOject, omitempty" yaml:"SubObject,omitempty"`
}
