package app
import "net/http"

func HealthCheck(w http.ResponseWriter, r *http.Request) {
	w.Write([]byte("Not Implemented"))
}

func Evaluate(w http.ResponseWriter, r *http.Request) {
	w.Write([]byte("Not Implemented"))
}

func GetAllPipelines(w http.ResponseWriter, r *http.Request) {
	w.Write([]byte("Not Implemented"))
}

func GetPipeline(w http.ResponseWriter, r *http.Request) {
	w.Write([]byte("Not Implemented"))
}