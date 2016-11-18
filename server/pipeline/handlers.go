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
	"github.com/coreos/etcd/client"
	"github.com/michael-golfi/rules/server/pipeline/config"
	"github.com/michael-golfi/rules/server/rule"
)

type PipelineHandler struct {
	Parser    inference.Parser
	etcd      *client.Client
	viper     *viper.Viper
	conf      map[string]config.Config
	pipelines map[string]*Pipeline
}

func NewPipelineHandler(etcd, path string) *PipelineHandler {
	c, err := config.CreateEtcdClient(etcd)
	if err != nil {
		log4go.Crashf("Cannot connect with ETCD: %s", err.Error())
	}

	// Create local cache
	cache := config.CreateViperConfig(etcd, path)

	conf := make(map[string]config.Config)

	config.LoadCache(cache)

	name := cache.GetString("name")
	var rules rule.RuleRepository
	var schema []inference.Field
	cache.UnmarshalKey("rules", &rules)
	cache.UnmarshalKey("schema", &schema)

	conf[name] = config.Config{
		Name: name,
		Rules: rules,
		Schema: schema,
	}

	// Watch remote config async
	go config.WatchConfig(cache, conf)

	return &PipelineHandler{
		etcd: c,
		Parser: inference.Parser{},
		viper: cache,
		conf: conf,
	}
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

	pipeline := NewPipeline(config, in)
	p.pipelines[config.Name] = pipeline
}

func (p *PipelineHandler) ReadPipelineConfig(w http.ResponseWriter, r *http.Request) {
	name := mux.Vars(r)["name"]
	conf := p.conf[name]

	if err := json.NewEncoder(w).Encode(conf); err != nil {
		message := fmt.Sprintf("Could not encode Pipeline: %s", err.Error())
		log4go.Error(message)
		w.WriteHeader(http.StatusInternalServerError)
		w.Write([]byte(message))
	}
}

func (p *PipelineHandler) Evaluate(w http.ResponseWriter, r *http.Request) {

	var data interface{}

	if err := json.NewDecoder(r.Body).Decode(&data); err != nil {
		message := fmt.Sprintf("Could not decode data: %s", err.Error())
		log4go.Error(message)
		w.WriteHeader(http.StatusInternalServerError)
		w.Write([]byte(message))
	}

	fields := p.Parser.Parse(data)
	pipeName, err := config.FindConf(&p.Parser, fields, p.conf)

	if err != nil {
		message := fmt.Sprintf("Could not find matching pipeline: %s", err.Error())
		log4go.Error(message)
		w.WriteHeader(http.StatusInternalServerError)
		w.Write([]byte(message))
	}

	pipeline := p.pipelines[pipeName]
	pipeline.Input(data)

}