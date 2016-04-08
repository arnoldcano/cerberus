#!/bin/bash

set -e

#setup service discovery
docker-machine create \
    -d virtualbox \
    cerberus-consul

export CONSUL_IP=$(docker-machine ip cerberus-consul)

#start consul
docker $(docker-machine config cerberus-consul) run \
  -d \
  -p 8500:8500 \
  -h consul \
  --restart always \
  gliderlabs/consul-server -server -bootstrap

#setup swarm master
docker-machine create \
    -d virtualbox \
    --swarm \
    --swarm-master \
    --swarm-discovery="consul://$CONSUL_IP:8500" \
    --engine-opt="cluster-store=consul://$CONSUL_IP:8500" \
    --engine-opt="cluster-advertise=eth1:2376" \
    cerberus-master

#start swarm master registrator
docker $(docker-machine config cerberus-master) run \
  -d \
  --name=cerberus_registrator \
  -h $(docker-machine ip cerberus-master) \
  --volume=/var/run/docker.sock:/tmp/docker.sock \
  gliderlabs/registrator:latest \
  consul://${CONSUL_IP}:8500

#setup swarm slave
docker-machine create \
    -d virtualbox \
    --swarm \
    --swarm-discovery="consul://$CONSUL_IP:8500" \
    --engine-opt="cluster-store=consul://$CONSUL_IP:8500" \
    --engine-opt="cluster-advertise=eth1:2376" \
    cerberus-slave

#start swarm slave registrator
docker $(docker-machine config cerberus-slave) run \
  -d \
  --name=cerberus_registrator \
  -h $(docker-machine ip cerberus-slave) \
  --volume=/var/run/docker.sock:/tmp/docker.sock \
  gliderlabs/registrator:latest \
  consul://${CONSUL_IP}:8500

#start swarm services
eval $(docker-machine env --swarm cerberus-master)
docker-compose -f docker-compose.yml up -d
