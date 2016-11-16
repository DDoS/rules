# dub run --  -f test/resource/increment.p -i "{\"anInt\": {\"i\": 2}, \"aFloat\": {\"f\": 7.5}}"

def Numbers: {AnInt anInt, AFloat aFloat}

def AnInt: {sint64 i}
def AFloat: {fp32 f}

when (Numbers numbers):
    return numbers.anInt.i != numbers.aFloat.f;

then (Numbers numbers):
    return {anInt: {i: numbers.anInt.i + sint64(numbers.aFloat.f)}, aFloat: numbers.aFloat}
