# Language Server

## Description

The Language Server is responsible for creating a RESTful interface to P star. It allows evaluation of P star programs and input variables.

In order to test the server:

``` bash

# Compile
dub

# Run
./langserver

# Test
curl -X POST -H "Content-Type: application/json" -d \
'{
	"input":"{\"anInt\": {\"i\": 2}, \"aFloat\": {\"f\": 7.5}}",
	"source":"def Numbers: {AnInt anInt, AFloat aFloat}\n\ndef AnInt: {sint64 i}\ndef AFloat: {fp32 f}\n\nwhen (Numbers numbers):\n    return numbers.anInt.i != numbers.aFloat.f;\n\nthen (Numbers numbers):\n    return {anInt: {i: numbers.anInt.i + sint64(numbers.aFloat.f)}, aFloat: numbers.aFloat}"
 }' \ 
"http://localhost:8080/api/v1/rules/:ruleset"
```