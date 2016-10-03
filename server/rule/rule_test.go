package rule

import (
	"testing"
	"github.com/stretchr/testify/assert"
)

type Value struct {
	value int
}

func (v Value) Value() int {
	return v.value
}

type Val interface {
	Value() int
}

func getInts(args []interface{}) []int {
	nums := make([]int, len(args))
	for i, v := range args {
		nums[i] = v.(int)
	}
	return nums
}

func TestAction_Execute(t *testing.T) {
	count := 0

	o1 := Output{
		Func: func(args []interface{}) {
			count = 10
		},
	}

	o2 := Output{
		Func: func(args []interface{}) {
			count = 20
		},
	}

	c := Conditional{
		Predicate: func(args []interface{}) bool {
			ints := getInts(args)
			return ints[0] > 10
		},

		True: o2,
		False: o1,
	}

	a := Action{
		Func: func(args []interface{}) interface{} {
			acc := 1
			nums := getInts(args)
			for i := range nums {
				acc *= nums[i]
			}
			return acc
		},
		NextRule: c,
	}

	next, res := a.Execute([]interface{}{2, 2})
	next1, _ := next.Execute([]interface{}{res})
	next1.Execute(nil)

	assert.Equal(t, 10, count)

	next, res = a.Execute([]interface{}{3, 3})
	next1, _ = next.Execute([]interface{}{res})
	next1.Execute(nil)

	assert.Equal(t, 10, count)

	next, res = a.Execute([]interface{}{4, 3})
	next1, _ = next.Execute([]interface{}{res})
	next1.Execute(nil)

	assert.Equal(t, 20, count)
}