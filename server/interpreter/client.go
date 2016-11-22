package interpreter

import (
	"net/url"
	"net/http"
	"io/ioutil"
	"github.com/michael-golfi/log4go"
)

type Handler struct {
	Run url.URL
	Add url.URL
}

type Message struct {
	Source string `json:"source"`
	Input  string `json:"input"`
}

// Creates a new instance of a http client for langserver
// Requires the baseUrl to be of the form: http://$host:$port/$basePath/[add|run]
func NewHandler(baseUrl string) (*Handler, error) {
	add, err := url.Parse(baseUrl + "/add")
	if err != nil {
		return nil, err
	}

	run, err := url.Parse(baseUrl + "/run")
	if err != nil {
		return nil, err
	}

	return &Handler{
		Run: *run,
		Add: *add,
	}, err
}

func (h *Handler) AddRule(name, source string) (string, error) {
	return request(name, h.Add.String(), "source", source)
}

func (h *Handler) Evaluate(name, input string) (string, error) {
	return request(name, h.Run.String(), "input", input)
}

func request(name, uri, key, val string) (string, error) {
	form := url.Values{}
	form.Add("name", name)
	form.Add(key, val)

	log4go.Debug("Form Data: %s", form.Encode())
	resp, err := http.PostForm(uri, form)
	if err != nil {
		log4go.Error("Could not evaluate input: %s", err.Error())
		return "", err
	}

	defer resp.Body.Close()

	body, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return "", err
	}

	return string(body), nil
}