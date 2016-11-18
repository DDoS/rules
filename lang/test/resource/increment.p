# dub run -- -f test/resource/increment.p -i "{\"anInt\": {\"i\": 2}, \"floats\": {\"fs\": [4, 7]}}"

def Numbers: {AnInt anInt, Floats floats}

def AnInt: {sint64 i}
def Floats: {fp32[] fs}

when (Numbers numbers):
    return numbers.floats.fs.len() > 1

then (Numbers numbers):
    return {anInt: {i: numbers.anInt.i + numbers.floats.fs[1]}, floats: numbers.floats}
