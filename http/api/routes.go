package api

import "github.com/michael-golfi/go-http-utils"

var Routes = util.Routes{
	util.Route{
		"Health Check Route",
		"GET",
		"/health",
		HealthCheck,
	},

	util.Route{
		"Read Pipeline Config",
		"HEAD",
		"/",
		ReadPipelineConfig,
	},

	util.Route{
		"Evaluate Object",
		"POST",
		"/",
		Evaluate,
	},
}
