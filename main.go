package main

import (
	"fmt"
	"log"
	"net/http"
	"os"

	"github.com/garyburd/redigo/redis"
)

func indexHandler(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusOK)
}

func statsHandler(w http.ResponseWriter, r *http.Request) {
	c, err := redis.Dial("tcp", "redis:6379")
	if err != nil {
		log.Fatal(err)
	}
	defer c.Close()

	h, _ := os.Hostname()
	c.Do("INCR", h)

	w.Header().Set("Content-Type", "text/html; charset=UTF-8")
	fmt.Fprintf(w, "<style>table { border-collapse: collapse; } table, th, td { border: 1px solid black; }</style>")
	fmt.Fprintf(w, "<h3>Stats</h3>")
	fmt.Fprintf(w, "<table><tr><th>Container</th><th>Hits</th></tr>")
	keys, _ := redis.Strings(c.Do("KEYS", "*"))
	for _, k := range keys {
		v, _ := redis.Int(c.Do("GET", k))
		fmt.Fprintf(w, "<tr><td>%s</td>", k)
		fmt.Fprintf(w, "<td>%d</td></tr>", v)
	}
	fmt.Fprintf(w, "</table>")
}

func main() {
	http.HandleFunc("/", indexHandler)
	http.HandleFunc("/stats", statsHandler)
	http.ListenAndServe(":8080", nil)
}
