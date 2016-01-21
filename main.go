package main
import (
	"github.com/spf13/viper"
	"github.com/michael-golfi/log4go"
	"github.com/michael-golfi/go-http-utils"
	"github.com/michael-golfi/rules/app"
	"net/http"
)

func main() {
	configure()

	router := util.NewRouter(app.Routes)
	log4go.Crash(http.ListenAndServe(":8080", router))
}

func configure(){
	viper.SetConfigFile("config.yaml")
	viper.SetConfigType("yaml")
	viper.AddConfigPath("./config")
	viper.WatchConfig()

	if err := viper.ReadInConfig(); err != nil {
		log4go.Error("Fatal error config file: %s \n", err.Error())
	}
}