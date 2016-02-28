#!/bin/bash

set -e

docker-machine create \
    -d virtualbox \
    cerberus-consul

docker $(docker-machine config cerberus-consul) run \
    -d \
    -p "8500:8500" \
    progrium/consul \
    -server \
    -bootstrap

docker-machine create \
    -d virtualbox \
    --swarm \
    --swarm-master \
    --swarm-discovery="consul://$(docker-machine ip cerberus-consul):8500" \
    --engine-opt="cluster-store=consul://$(docker-machine ip cerberus-consul):8500" \
    --engine-opt="cluster-advertise=eth1:2376" \
    cerberus-master

docker-machine create \
    -d virtualbox \
    --swarm \
    --swarm-discovery="consul://$(docker-machine ip cerberus-consul):8500" \
    --engine-opt="cluster-store=consul://$(docker-machine ip cerberus-consul):8500" \
    --engine-opt="cluster-advertise=eth1:2376" \
    cerberus-node-1

docker-machine create \
    -d virtualbox \
    --swarm \
    --swarm-discovery="consul://$(docker-machine ip cerberus-consul):8500" \
    --engine-opt="cluster-store=consul://$(docker-machine ip cerberus-consul):8500" \
    --engine-opt="cluster-advertise=eth1:2376" \
    cerberus-node-2

docker-machine create \
    -d virtualbox \
    cerberus-interlock

eval $(docker-machine env --swarm cerberus-master)

docker $(docker-machine config cerberus-interlock) run \
    -d \
    -p "80:80" \
    -v $DOCKER_CERT_PATH:/certs:ro \
    ehazlett/interlock \
    --swarm-url $DOCKER_HOST \
    --swarm-tls-ca-cert=/certs/ca.pem \
    --swarm-tls-cert=/certs/server.pem \
    --swarm-tls-key=/certs/server-key.pem \
    --plugin haproxy start
