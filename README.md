# Cerberus

**Cerberus** is an example multi-host Docker Swarm using Docker Machine, Docker Compose, and Traefik.

## Prerequisites
This software must be installed first

#### 1. Install Virtualbox
#### 2. Install Docker Toolbox
#### 3. Install Go

## Setup the docker swarm hosts
This is how you setup the multi-host swarm

#### 1. Create the host for consul
```
docker-machine create -d virtualbox cerberus-consul
```
#### 2. Run consul for service discovery
```
docker $(docker-machine config cerberus-consul) run \
  -d \
  -p "8500:8500" \
  -h "consul" \
  progrium/consul -server -bootstrap
```
#### 3. Create the host for the swarm master
```
docker-machine create \
    -d virtualbox \
    --swarm \
    --swarm-master \
    --swarm-discovery="consul://$(docker-machine ip cerberus-consul):8500" \
    --engine-opt="cluster-store=consul://$(docker-machine ip cerberus-consul):8500" \
    --engine-opt="cluster-advertise=eth1:2376" \
    cerberus-master
```
#### 4. Create the host for the swarm slave
```
docker-machine create \
    -d virtualbox \
    --swarm \
    --swarm-discovery="consul://$(docker-machine ip cerberus-consul):8500" \
    --engine-opt="cluster-store=consul://$(docker-machine ip cerberus-consul):8500" \
    --engine-opt="cluster-advertise=eth1:2376" \
    cerberus-slave
```
#### 5. Create the overlay network
```
eval $(docker-machine env --swarm cerberus-master)
docker network create -d overlay \
    --subnet=10.0.9.0/24 \
    cerberus-net
```
#### 6. Deploy load balancer
```
docker $(docker-machine config cerberus-master) run \
    -d \
    -p 80:80 -p 8080:8080 \
    --net=cerberus-net \
    -v /var/lib/boot2docker/:/ssl \
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
```
## Run the cerberus app
This compiles the **Cerberus** app statically so that the container sizes are small

#### 1. Build the cerberus code statically
```
GO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o main .
```
#### 2. Run cerberus app in the cluster
```
docker-compose up -d
```
#### 3. Create host entry in /etc/hosts for cluster
Add "$(docker-machine ip cerberus-master) web.docker.local" to /etc/host

## Scaling and load testing the cerberus application
This is how you can scale the **Cerberus** instances in the cluster and load test

#### 1. Load test cerberus using ab
```
ab -n 1000 -c 50 -l http://$(docker-machine ip cerberus-master)/stats
```
#### 2. Scale cerberus up!
```
docker-compose scale web=10
```
#### 3. Load test cerberus again
```
ab -n 1000 -c 50 -l http://$(docker-machine ip cerberus-master)/stats
```
