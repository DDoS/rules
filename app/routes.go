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
		"Read Pipeline Config",
		"HEAD",
		"/{namespace}/{pipeline_name}",
		ReadPipelineConfig,
	},

	util.Route{
		"Evaluate Object",
		"POST",
		"/{namespace}/{pipeline_name}",
		Evaluate,
	},

	util.Route{
		"Save Pipeline",
		"PUT",
		"/{namespace}/{pipeline_name}",
		SavePipeline,
	},

	util.Route{
		"Delete Pipeline",
		"DELETE",
		"/{namespace}/{pipeline_name}",
		DeletePipeline,
	},
}
