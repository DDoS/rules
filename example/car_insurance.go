package main

import (
	"net/http"
	"fmt"
	"encoding/json"
)

const (
	MARRIED = "married"
	SINGLE = "single"
	WIDOW = "widow"
	MALE = "male"
	FEMALE = "female"
)

type InsurancePolicy struct {
	Id                int `json:"id"`
	Name              string `json:"name"`
	Age               int `json:"age"`
	MaritalStatus     string `json:"maritalStatus"`
	Gender            string `json:"gender"`
	AccidentsOnRecord bool `json:"accidentsOnRecord"`
	Premium           int `json:"premium"`
}

func process(w http.ResponseWriter, r *http.Request) {
	if r.Method != "POST" {
		return
	}

	var ins InsurancePolicy

	if err := json.NewDecoder(r.Body).Decode(&ins); err != nil {
		fmt.Errorf("Error Decoding: %s", err.Error())
	}

	fmt.Printf("Processing Insurance Policy For Customer: %s\n", ins.Name)

	ins.Premium = 100

	if ins.MaritalStatus == MARRIED {
		ins.Premium -= 10
	} else {
		ins.Premium += 25
	}

	if ins.Gender == FEMALE {
		ins.Premium -= 10
	} else {
		ins.Premium += 10
	}

	if ins.Age < 25 {
		ins.Premium += 25
	} else {
		ins.Premium -= 25
	}

	if ins.AccidentsOnRecord {
		// Do Nothing
	} else {
		ins.Premium += 25
	}

	if err := json.NewEncoder(w).Encode(&ins); err != nil {
		fmt.Errorf("Error Encoding: %s", err.Error())
	}
}

func main() {
	http.HandleFunc("/", process)
	http.ListenAndServe(":8080", nil)
}