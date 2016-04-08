package main

import (
	"encoding/json"
	"net/http"
	"os"
	"time"

	"github.com/garyburd/redigo/redis"
)

var pool *redis.Pool

type Stats struct {
	Containers []Container `json:"containers"`
}

type Container struct {
	Hostname string `json:"hostname"`
	Hits     int    `json:"hits"`
}

func IndexHandler(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusOK)
}

func StatsHandler(w http.ResponseWriter, r *http.Request) {
	pool := newRedisPool("redis:6379")
	c := pool.Get()
	defer c.Close()

	h, _ := os.Hostname()
	c.Do("INCR", h)

	keys, _ := redis.Strings(c.Do("KEYS", "*"))
	containers := make([]Container, len(keys))
	for i, k := range keys {
		v, _ := redis.Int(c.Do("GET", k))
		containers[i] = Container{Hostname: k, Hits: v}
	}
	stats := &Stats{Containers: containers}

	w.Header().Set("Content-Type", "application/json")
	if err := json.NewEncoder(w).Encode(stats); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
}

func main() {
	http.HandleFunc("/", IndexHandler)
	http.HandleFunc("/stats", StatsHandler)
	http.ListenAndServe(":8080", nil)
}

func newRedisPool(server string) *redis.Pool {
	return &redis.Pool{
		MaxIdle:     3,
		IdleTimeout: 240 * time.Second,
		Dial: func() (redis.Conn, error) {
			c, err := redis.Dial("tcp", server)
			if err != nil {
				return nil, err
			}
			return c, err
		},
		TestOnBorrow: func(c redis.Conn, t time.Time) error {
			_, err := c.Do("PING")
			return err
		},
	}
}
