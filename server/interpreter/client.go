package interpreter

import (
	"net/url"
	"net/http"
	"bytes"
	"io/ioutil"
	"encoding/json"
)

type Handler struct {
	Uri url.URL
}

type Message struct {
	Source string `json:"source"`
	Input  string `json:"input"`
}

func NewHandler(uri string) (*Handler, error) {
	u, err := url.Parse(uri)

	return &Handler{
		Uri: *u,
	}, err
}

func (h *Handler) Evaluate(source, input string) (string, error) {

	msg, err := json.Marshal(&Message{
		Source: source,
		Input: input,
	})

	req, err := http.NewRequest("POST", h.Uri.String(), bytes.NewBuffer(msg))

	req.Header.Set("Content-Type", "application/json")

	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		return "", err
	}

	defer resp.Body.Close()

	body, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return "", err
	}

	return string(body), nil
}