#!/bin/bash

set -e

docker-machine create -d virtualbox cerberus-consul

eval "$(docker-machine env cerberus-consul)"
docker run -d \
    -p "8500:8500" \
    -h "consul" \
    progrium/consul -server -bootstrap

docker-machine create -d virtualbox \
    --swarm --swarm-master \
    --swarm-discovery="consul://$(docker-machine ip cerberus-consul):8500" \
    --engine-opt="cluster-store=consul://$(docker-machine ip cerberus-consul):8500" \
    --engine-opt="cluster-advertise=eth1:2376" \
    cerberus-master

docker-machine create -d virtualbox \
    --swarm \
    --swarm-discovery="consul://$(docker-machine ip cerberus-consul):8500" \
    --engine-opt="cluster-store=consul://$(docker-machine ip cerberus-consul):8500" \
    --engine-opt="cluster-advertise=eth1:2376" \
    cerberus-slave

eval $(docker-machine env --swarm cerberus-master)
docker network create -d overlay \
    --subnet=10.0.9.0/24 \
    cerberus-net

docker $(docker-machine config cerberus-master) run \
    -d \
    -p 80:80 -p 8080:8080 \
    --net=cerberus-net \
    -v /Users/arnoldcano/.docker/machine/machines/cerberus-master/:/ssl \
    traefik \
    -l DEBUG \
    -c /dev/null \
    --docker \
    --docker.domain=docker.local \
    --docker.endpoint=tcp://$(docker-machine ip cerberus-master):3376 \
    --docker.tls \
    --docker.tls.ca=/ssl/ca.pem \
    --docker.tls.cert=/ssl/server.pem \
    --docker.tls.key=/ssl/server-key.pem \
    --docker.tls.insecureSkipVerify \
    --docker.watch \
    --web
