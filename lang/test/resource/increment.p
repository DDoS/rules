def AnInt: {sint64 v}

when (AnInt i):
    return i.v > 0

then (AnInt i):
    return {v: i.v + 1}
