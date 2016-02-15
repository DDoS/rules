package main

import (
	"github.com/michael-golfi/go-http-utils"
	"github.com/michael-golfi/log4go"
	"github.com/michael-golfi/rules/app"
	"github.com/spf13/viper"
	"gopkg.in/fsnotify.v1"
	"net/http"
)

func main() {
	configure()

	router := util.NewRouter(app.Routes)
	log4go.Crash(http.ListenAndServe(":8080", router))
}

func configure() {
	viper.SetConfigFile("config.yaml")
	viper.SetConfigType("yaml")
	viper.AddConfigPath("./config")
	viper.WatchConfig()
	viper.OnConfigChange(func(e fsnotify.Event) {
		log4go.Info("Config Changed: %s", e.String())
	})
	if err := viper.ReadInConfig(); err != nil {
		log4go.Error("Fatal error config file: %s \n", err.Error())
	}
}
