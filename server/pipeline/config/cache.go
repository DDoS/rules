package config

import (
	"github.com/spf13/viper"
	"github.com/michael-golfi/log4go"
	"time"
	"fmt"
	"github.com/michael-golfi/rules/server/inference"
	"errors"
	"github.com/michael-golfi/rules/server/rule"
)

func CreateViperConfig(host, path string) *viper.Viper {
	cache := viper.New()
	cache.AddRemoteProvider("etcd", host, path)
	cache.SetConfigType("yaml")

	if err := cache.ReadRemoteConfig(); err != nil {
		log4go.Crashf("Cannot read from etcd: %s", err.Error())
	}

	return cache
}

func WatchConfig(cache *viper.Viper, config map[string]Config) {
	for {
		time.Sleep(time.Second * 5)
		err := cache.WatchRemoteConfig()
		if err != nil {
			log4go.Error(fmt.Sprintf("Can't read remote config: %s", err.Error()))
			continue
		}

		name := cache.GetString("name")
		var rules rule.RuleRepository
		var schema []inference.Field
		cache.UnmarshalKey("rules", &rules)
		cache.UnmarshalKey("schema", &schema)

		config[name] = Config{
			Name: name,
			Rules: rules,
			Schema: schema,
		}

		log4go.Info("Read Config: %v", config)
	}
}

// Finds name of pipeline with matching field schema
func FindConf(p *inference.Parser, field []inference.Field, conf map[string]*Config) (string, error) {
	for k, v := range conf {
		if p.FuzzyEqual(v.Schema, field) {
			return k, nil
		}
	}

	return "", errors.New("Cannot find matching schema")
}