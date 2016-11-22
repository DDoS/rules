package pipeline

import (
	"net/http"
	"github.com/michael-golfi/log4go"
	"fmt"
	"encoding/json"
	"github.com/gorilla/mux"
	"github.com/michael-golfi/rules/server/inference"
	"github.com/michael-golfi/rules/server/pipeline/config"
	"github.com/fsnotify/fsnotify"
	"io/ioutil"
	"sync"
	"github.com/michael-golfi/rules/server/interpreter"
	"github.com/ghodss/yaml"
)

type PipelineHandler struct {
	RulesUrl  string
	Parser    inference.Parser
	conf      map[string]*config.Config
	pipelines map[string]*Pipeline
	sync.RWMutex
}

func NewPipelineHandler(rulesUri, filename string) *PipelineHandler {
	conf := make(map[string]*config.Config)
	pipes := make(map[string]*Pipeline)

	h := &PipelineHandler{
		RulesUrl: rulesUri,
		Parser: inference.Parser{},
		pipelines: pipes,
		conf: conf,
	}

	go h.WatchConfigFile(filename)

	return h
}

func (p *PipelineHandler) WatchConfigFile(filename string) {
	watcher, err := fsnotify.NewWatcher()
	if err != nil {
		log4go.Error(err.Error())
	}
	defer watcher.Close()

	if err := watcher.Add(filename); err != nil {
		log4go.Error(err.Error())
	}

	watcher.Events <- fsnotify.Event{
		Op: fsnotify.Write,
	}

	for {
		select {
		case event := <-watcher.Events:
			log4go.Info("Event: %s, Modified File: %s", event.String(), filename)

			conf, err := p.ReadConfigFile(filename)
			if err != nil {
				log4go.Error("Cannot read config: %s", err.Error())
				break
			}

			if err := p.NewPipe(conf, p.RulesUrl); err != nil {
				log4go.Error("Cannot create pipeline: %s", err.Error())
				break
			}
			log4go.Info("Updated pipeline: %s", conf.Name)

		case err := <-watcher.Errors:
			log4go.Error("Watcher Error: %s", err)
		}
	}
}

func (p *PipelineHandler) ReadConfigFile(filename string) (*config.Config, error) {
	b, err := ioutil.ReadFile(filename)
	if err != nil {
		return nil, err
	}

	var conf config.Config
	if err := yaml.Unmarshal(b, &conf); err != nil {
		return nil, err
	}
	return &conf, nil
}

func (p *PipelineHandler) SetRoutes(r *mux.Router) {
	r.HandleFunc("/pipeline/{name}", p.ReadPipelineConfig).Methods("HEAD")
	r.HandleFunc("/pipeline", p.Evaluate).Methods("POST")
	r.HandleFunc("/pipeline", p.NewPipeline).Methods("PUT")
}

func (p *PipelineHandler) NewPipeline(w http.ResponseWriter, r *http.Request) {
	var config *config.Config
	if err := json.NewDecoder(r.Body).Decode(config); err != nil {
		message := fmt.Sprintf("Could not create Pipeline: %s", err.Error())

		log4go.Error(message)
		w.WriteHeader(http.StatusInternalServerError)
		w.Write([]byte(message))
	}

	if err := p.NewPipe(config, p.RulesUrl); err != nil {
		log4go.Error("Could not create pipeline: %s", err.Error())
	}
}

func (p *PipelineHandler) ReadPipelineConfig(w http.ResponseWriter, r *http.Request) {
	name := mux.Vars(r)["name"]

	if err := json.NewEncoder(w).Encode(p.GetConf(name)); err != nil {
		message := fmt.Sprintf("Could not encode Pipeline: %s", err.Error())
		log4go.Error(message)
		w.WriteHeader(http.StatusInternalServerError)
		w.Write([]byte(message))
	}
}

func (p *PipelineHandler) Evaluate(w http.ResponseWriter, r *http.Request) {
	var data interface{}
	d := json.NewDecoder(r.Body)
	d.UseNumber()

	if err := d.Decode(&data); err != nil {
		message := fmt.Sprintf("Could not decode data: %s", err.Error())
		log4go.Error(message)
		w.WriteHeader(http.StatusInternalServerError)
		w.Write([]byte(message))
		return
	}

	if err := p.Eval(data); err != nil {
		message := fmt.Sprintf("Could not eval input: %s", err.Error())
		log4go.Error(message)
		w.WriteHeader(http.StatusInternalServerError)
		w.Write([]byte(message))
		return
	}
}

func (p *PipelineHandler) GetConf(name string) *config.Config {
	return p.conf[name]
}

func (p *PipelineHandler) NewPipe(conf *config.Config, ruleUri string) error {
	client, err := interpreter.NewHandler(ruleUri)
	if err != nil {
		return err
	}

	pipeline := NewPipeline(conf, client)

	if err := pipeline.Start(client); err != nil {
		return err
	}

	p.conf[conf.Name] = conf
	p.pipelines[conf.Name] = pipeline

	return nil
}

func (p *PipelineHandler) Eval(data interface{}) error {
	fields, err := p.Parser.Parse(data)
	if err != nil {
		return err
	}

	pipeName, err := config.FindConf(&p.Parser, fields, p.conf)
	if err != nil {
		return err
	}

	if err := p.pipelines[pipeName].Input(data); err != nil {
		return err
	}
	return nil
}