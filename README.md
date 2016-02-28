# Cerberus

**Cerberus** is an example multi-host Docker Swarm using Docker Machine, Docker Compose, Consul, and Interlock.

## Prerequisites
This software must be installed first

#### 1. Install Virtualbox
#### 2. Install Docker Toolbox (version 1.10 or above)
#### 3. Install Go

## Setup the docker swarm hosts automatically
This is how you setup the multi-host swarm automatically.

#### 1. Run the setup_swarm.sh script
#### 2. Skip to setting up the /etc/hosts file below

## Setup the docker swarm hosts manually
This is how you setup the multi-host swarm manually.

#### 1. Create the host for consul
```
docker-machine create \
    -d virtualbox \
    cerberus-consul
```
#### 2. Run consul for service discovery
```
docker $(docker-machine config cerberus-consul) run \
    -d \
    -p "8500:8500" \
    progrium/consul \
    -server \
    -bootstrap
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
#### 4. Create the host for the first swarm node
```
docker-machine create \
    -d virtualbox \
    --swarm \
    --swarm-discovery="consul://$(docker-machine ip cerberus-consul):8500" \
    --engine-opt="cluster-store=consul://$(docker-machine ip cerberus-consul):8500" \
    --engine-opt="cluster-advertise=eth1:2376" \
    cerberus-node-1
```
#### 5. Create the host for the second swarm node
```
docker-machine create \
    -d virtualbox \
    --swarm \
    --swarm-discovery="consul://$(docker-machine ip cerberus-consul):8500" \
    --engine-opt="cluster-store=consul://$(docker-machine ip cerberus-consul):8500" \
    --engine-opt="cluster-advertise=eth1:2376" \
    cerberus-node-2
```
#### 6. Load the environment variables for the swarm master
```
eval $(docker-machine env --swarm cerberus-master)
```
#### 7. Create the host for interlock
```
docker-machine create \
    -d virtualbox \
    cerberus-interlock
```
#### 8. Run interlock for load balancing using haproxy
```
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
```

## Setup the /etc/hosts file locally for interlock
This is how you get interlock to load balance over your **Cerberus** instances.

#### 1. Get the ip address of the interlock host
```
docker-machine ip cerberus-interlock
```
#### 2. Add the ip address and domain to /etc/hosts
```
<cerberus-interlock-ip> cerberus.swarm.local
```
#### 3. Go to http://stats:interlock@cerberus.swarm.local/haproxy?stats in your browser

## Run the cerberus sample application
This compiles the **Cerberus** application statically so that the container sizes are small.

#### 1. Build the cerberus code statically
```
GO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o main .
```
#### 2. Build the cerberus docker image (based off the scratch docker image)
```
docker-compose build .
```
#### 3. Run cerberus in the swarm
```
docker-compose up -d
```
#### 4. Check the logs for cerberus
```
docker-compose logs
```
#### 5. Go to http://cerberus.swarm.local/stats in your browser

## Scaling and load testing the cerberus application
This is how you can scale the **Cerberus** instances in the swarm and load test the performance.

#### 1. Load test cerberus using ab
```
ab -n 1000 -c 50 http://cerberus.swarm.local/stats/
```
#### 2. Scale cerberus up!
```
docker-compose scale web=10
```
#### 3. Load test cerberus again
```
ab -n 1000 -c 50 http://cerberus.swarm.local/stats/
```
