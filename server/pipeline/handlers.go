package pipeline

import (
	"net/http"
	"github.com/michael-golfi/log4go"
	"fmt"
	"encoding/json"
	"github.com/gorilla/mux"
	"github.com/spf13/viper"
	_ "github.com/spf13/viper/remote"
	"github.com/michael-golfi/rules/server/inference"
	"github.com/michael-golfi/rules/server/pipeline/config"
	"github.com/coreos/etcd/clientv3"
	"github.com/fsnotify/fsnotify"
	"io/ioutil"
	"gopkg.in/yaml.v2"
	"sync"
	"github.com/michael-golfi/rules/server/interpreter"
)

var (
	rulesUrl = "http://127.0.0.1:9090/api/v1/rules"
)

type PipelineHandler struct {
	Parser    inference.Parser
	etcd      *clientv3.Client
	viper     *viper.Viper
	conf      map[string]config.Config
	pipelines map[string]*Pipeline
	sync.RWMutex
}

func NewPipelineHandler(etcd, path string) *PipelineHandler {

	conf := make(map[string]config.Config)
	pipes := make(map[string]*Pipeline)

	h := &PipelineHandler{
		Parser: inference.Parser{},
		pipelines: pipes,
		conf: conf,
	}

	go func(filename string, h *PipelineHandler) {
		watcher, err := fsnotify.NewWatcher()
		if err != nil {
			log4go.Error(err.Error())
		}
		defer watcher.Close()

		err = watcher.Add(path)
		if err != nil {
			log4go.Error(err.Error())
		}

		watcher.Events <- fsnotify.Event{
			Op: fsnotify.Write,
		}

		for {
			select {
			case event := <-watcher.Events:
				log4go.Info("event:", event)
				log4go.Info("%s modified:", filename)

				b, err := ioutil.ReadFile(filename)
				if err != nil {
					log4go.Error("Cannot read file: %s", err.Error())
					break
				}

				var conf config.Config
				if err := yaml.Unmarshal(b, &conf); err != nil {
					log4go.Error("Cannot read yaml: %s", err.Error())
					break
				}

				client, err := interpreter.NewHandler(rulesUrl)
				if err != nil {
					log4go.Error("Could not parse rules url: %s", err.Error())
				}

				h.Lock()
				h.conf[conf.Name] = conf
				in := CreateInput()
				h.pipelines[conf.Name] = NewPipeline(&conf, in, client)
				h.pipelines[conf.Name].Start(client)
				h.Unlock()

				log4go.Info("Updated pipeline: %s", conf.Name)

			case err := <-watcher.Errors:
				log4go.Error("Watcher Error: %s", err)
			}
		}
	}(path, h)

	return h
}

func (p *PipelineHandler) SetRoutes(r *mux.Router) {
	r.HandleFunc("/pipeline/{name}", p.ReadPipelineConfig).Methods("HEAD")
	r.HandleFunc("/pipeline", p.Evaluate).Methods("POST")
	r.HandleFunc("/pipeline", p.NewPipeline).Methods("PUT")
}

func (p *PipelineHandler) NewPipeline(w http.ResponseWriter, r *http.Request) {
	in := CreateInput()

	var config *config.Config
	if err := json.NewDecoder(r.Body).Decode(config); err != nil {
		message := fmt.Sprintf("Could not create Pipeline: %s", err.Error())

		log4go.Error(message)
		w.WriteHeader(http.StatusInternalServerError)
		w.Write([]byte(message))
	}

	/**
	TODO - Cannot modify file in k8s since file changes don't propogate to other members
	b, err := yaml.Marshal(config)
	if err != nil {
		log4go.Error("Couldn't marshall yaml: %s", err.Error())
	}*/

	client, err := interpreter.NewHandler(rulesUrl)
	if err != nil {
		log4go.Error("Could not parse rules url: %s", err.Error())
	}

	pipeline := NewPipeline(config, in, client)

	p.Lock()
	p.pipelines[config.Name] = pipeline
	pipeline.Start(client)
	p.Unlock()
}

func (p *PipelineHandler) ReadPipelineConfig(w http.ResponseWriter, r *http.Request) {
	name := mux.Vars(r)["name"]

	p.RLock()
	conf := p.conf[name]
	p.RUnlock()

	if err := json.NewEncoder(w).Encode(conf); err != nil {
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

	fields, err := p.Parser.Parse(data)

	p.RLock()
	conf := p.conf
	pipeName, err := config.FindConf(&p.Parser, fields, conf)
	p.RUnlock()

	if err != nil {
		message := fmt.Sprintf("Could not find matching pipeline: %s", err.Error())
		log4go.Error(message)
		w.WriteHeader(http.StatusInternalServerError)
		w.Write([]byte(message))
		return
	}

	p.Lock()
	log4go.Info("Evaluating input for pipeline: %s", pipeName)
	if err := p.pipelines[pipeName].Input(data); err != nil {
		p.Unlock()
		log4go.Error("Could not evaluate input: %s", err.Error())
	}
	p.Unlock()
}