package app
import "github.com/michael-golfi/go-http-utils"

var Routes = util.Routes{
	util.Route{
		"Health Check Route",
		"GET",
		"/health",
		HealthCheck,
	},

	util.Route{
		"Evaluate Object",
		"POST",
		"/",
		Evaluate,
	},

	util.Route{
		"Get All Pipelines",
		"GET",
		"/",
		GetAllPipelines,
	},

	util.Route{
		"Get Pipeline",
		"GET",
		"/{PipelineName}",
		GetPipeline,
	},
}