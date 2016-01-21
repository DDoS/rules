package app
import "github.com/michael-golfi/go-http-utils"

var Routes = util.Routes{
	util.Route{
		"Health Check Route",
		"GET",
		"/health",
		HealthCheck,
	},
}