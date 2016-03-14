package lang

import (
    "reflect"
)

func runesContain(a []rune, b rune) bool {
    for _, r := range a {
        if r == b {
            return true
        }
    }
    return false
}

func runesEquals(a []rune, b []rune) bool {
    if len(a) != len(b) {
        return false
    }
    for i := range a {
        if a[i] != b[i] {
            return false
        }
    }
    return true
}

func joinString(things interface{}, joiner string) string {
    return join(things, joiner, "String")
}

func joinSource(things interface{}, joiner string) string {
    return join(things, joiner, "Source")
}

func join(things interface{}, joiner string, stringer string) string {
    values := reflect.ValueOf(things)
    s := ""
    length :=  values.Len() - 1
    if length < 0 {
        return s
    }
    for i := 0; i < length; i++ {
        s += getString(values.Index(i), stringer) + joiner
    }
    s += getString(values.Index(length), stringer)
    return s
}

func getString(value reflect.Value, stringer string) string {
    return value.MethodByName(stringer).Call(nil)[0].String()
}
