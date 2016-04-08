# Cerberus

**Cerberus** is an example multi-host Docker Swarm using Docker Machine, Docker Compose, Consul, Consul-Template, and Registrator.

## Prerequisites
This software must be installed first

#### 1. Install Virtualbox
#### 2. Install Docker Toolbox (version 1.10 or above)
#### 3. Install Go

## Setup the docker swarm hosts automatically
This is how you setup the multi-host swarm automatically.

#### 1. Run the `setup_swarm.sh` script
#### 2. Skip to running the cerberus sample application below

## Setup the docker swarm hosts manually
This is how you setup the multi-host swarm manually.

#### 1. Create the host for consul
```
docker-machine create \
    -d virtualbox \
    cerberus-consul
```
#### 2. Set CONSUL_IP environment variable
```
export CONSUL_IP=$(docker-machine ip cerberus-consul)
```
#### 3. Run consul for service discovery
```
docker $(docker-machine config cerberus-consul) run \
  -d \
  -p 8500:8500 \
  -h consul \
  --restart always \
  gliderlabs/consul-server -server -bootstrap
```
#### 4. Create the host for the swarm master
```
docker-machine create \
    -d virtualbox \
    --swarm \
    --swarm-master \
    --swarm-discovery="consul://$CONSUL_IP:8500" \
    --engine-opt="cluster-store=consul://$CONSUL_IP:8500" \
    --engine-opt="cluster-advertise=eth1:2376" \
    cerberus-master
```
#### 5. Run registrator for the swarm master
```
docker $(docker-machine config cerberus-master) run \
  -d \
  --name=cerberus_registrator \
  -h $(docker-machine ip cerberus-master) \
  --volume=/var/run/docker.sock:/tmp/docker.sock \
  gliderlabs/registrator:latest \
  consul://${CONSUL_IP}:8500
```
#### 6. Create the host for the swarm slave
```
docker-machine create \
    -d virtualbox \
    --swarm \
    --swarm-discovery="consul://$CONSUL_IP:8500" \
    --engine-opt="cluster-store=consul://$CONSUL_IP:8500" \
    --engine-opt="cluster-advertise=eth1:2376" \
    cerberus-slave
```
#### 7. Run registrator for the swarm slave
```
docker $(docker-machine config cerberus-slave) run \
  -d \
  --name=cerberus_registrator \
  -h $(docker-machine ip cerberus-slave) \
  --volume=/var/run/docker.sock:/tmp/docker.sock \
  gliderlabs/registrator:latest \
  consul://${CONSUL_IP}:8500
```
#### 8. Load the environment variables for the swarm master
```
eval $(docker-machine env --swarm cerberus-master)
```
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
## Check the services in consul
#### 1. Determine the ip address for consul
```
docker ps | grep nginx
```
#### 2. Set the NGINX_IP environment variable
```
export NGINX_IP=(ip address from above)
```
#### 3. Go to `http://$NGINX_IP:8500/ui/` in your browser
## Scaling and load testing the cerberus application
This is how you can scale the **Cerberus** instances in the swarm and load test the performance.

#### 1. Load test cerberus using ab
```
ab -n 1000 -c 50 -l http://$NGINX_IP/stats
```
#### 2. Scale cerberus up!
```
docker-compose scale web=10
```
#### 3. Load test cerberus again
```
ab -n 1000 -c 50 -l http://$NGINX_IP/stats
```
