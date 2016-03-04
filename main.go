package main

import (
	"encoding/json"
	"log"
	"net/http"
	"os"

	"github.com/garyburd/redigo/redis"
)

type stats struct {
	containers []container `json:"containers"`
}

type container struct {
	hostname string `json:"hostname"`
	hits     int    `json:"hits"`
}

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

	keys, _ := redis.Strings(c.Do("KEYS", "*"))
	containers := make([]container, len(keys))
	for i, k := range keys {
		v, _ := redis.Int(c.Do("GET", k))
		containers[i] = container{hostname: k, hits: v}
	}
	stats := &stats{containers: containers}

	w.Header().Set("Content-Type", "application/json")
	if err := json.NewEncoder(w).Encode(stats); err != nil {
		log.Fatal(err)
	}
}

func main() {
	http.HandleFunc("/", indexHandler)
	http.HandleFunc("/stats", statsHandler)
	http.ListenAndServe(":8080", nil)
}
