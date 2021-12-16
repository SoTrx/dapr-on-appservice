# Wether to try to optimize the size of the docker images
OPTIMIZE=0
# Dapr runtime version to use
DAPR_VERSION=1.5.0

# Paths shannanigans 
MKFILE_PATH := $(abspath $(lastword $(MAKEFILE_LIST)))
PROJECT_ROOT := $(dir $(MKFILE_PATH))
SRC_ROOT := ${PROJECT_ROOT}/src

# Local demo variables
LOCAL_COMPONENTS_PATH := ${SRC_ROOT}/components-local
LOCAL_CONFIG_PATH := ${SRC_ROOT}/config-local
DEMO_NETWORK := meh
DEMO_PLACEMENT_NAME := placement
DEMO_REDIS_NAME := redis
DEMO_CONSUL_NAME := consul

# Build all the custom containers
build: b-satcar b-node b-python

# Builds the generic sidecar to be attached to every app
b-satcar:
	cd ${SRC_ROOT}/using-satcars/satcar &&\
	docker build --build-arg OPTIMIZE=${OPTIMIZE} --build-arg DAPR_VERSION=${DAPR_VERSION} -t satcar .

# Builds the node subscriber app
b-node:
	cd ${SRC_ROOT}/using-satcars/node &&\
	docker build --build-arg OPTIMIZE=${OPTIMIZE} -t nodeapp .

# Builds the python publisher app
b-python:
	cd ${SRC_ROOT}/using-satcars/python &&\
	docker build --build-arg OPTIMIZE=${OPTIMIZE} -t pythonapp .

# Starts the demo app
run: build start-external 
	docker run -d --name pythonapp --network=${DEMO_NETWORK} -e DAPR_HOST=satcarpython -it pythonapp
	docker run -d --name=nodeapp --network=${DEMO_NETWORK} -e DAPR_HOST=satcarnode -it nodeapp
	docker run -d --name satcarnode --network=${DEMO_NETWORK} -e PLACEMENT_HOST=${DEMO_PLACEMENT_NAME} -e PLACEMENT_PORT=50006 -e APP_ID=nodeapp -e APP_PORT=80 -e APP_HOST=nodeapp -v ${LOCAL_COMPONENTS_PATH}:/components -v ${LOCAL_CONFIG_PATH}:/config satcar
	docker run -d --name satcarpython --network=${DEMO_NETWORK} -e PLACEMENT_HOST=${DEMO_PLACEMENT_NAME} -e PLACEMENT_PORT=50006 -e APP_ID=pythonapp -e APP_PORT=80 -e APP_HOST=pythonapp -v ${LOCAL_COMPONENTS_PATH}:/components -v ${LOCAL_CONFIG_PATH}:/config satcar
	docker logs -f nodeapp


# Stops all running containers
stop:
	docker stop satcarnode satcarpython pythonapp nodeapp ${DEMO_PLACEMENT_NAME} ${DEMO_REDIS_NAME} ${DEMO_CONSUL_NAME} || echo "hey"
	docker rm satcarnode satcarpython pythonapp nodeapp ${DEMO_PLACEMENT_NAME} ${DEMO_REDIS_NAME} ${DEMO_CONSUL_NAME}  || echo "hey"


# Pulling and starting all external servcices
# Powershell doesn't have a "true" command, so we use "echo" to set the return code to 0  
# where a failure doesn't matter
start-external: stop
	docker network create ${DEMO_NETWORK} || echo "hey"
	docker run -d --network ${DEMO_NETWORK} --name ${DEMO_PLACEMENT_NAME} -p "50006:50006" -it daprio/dapr ./placement -port 50006
	docker run -d --network ${DEMO_NETWORK} --name ${DEMO_REDIS_NAME} -it redis
	docker run -d --network ${DEMO_NETWORK} --name ${DEMO_CONSUL_NAME}  -it consul


