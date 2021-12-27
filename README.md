# Dapr on App Service Environment

The purpose of this repository is to include [Dapr](https://dapr.io/), in an [Azure App Service Environment (ASE)](https://docs.microsoft.com/en-us/azure/app-service/environment/overview). This is an exploratory solution, intended to find ways to add the covenience of Dapr in the already well-established ASE ecosystem.

## Considered solutions

+ Using App Service built-in support for docker-compose (see subdirectory : @TDB)
    + **Advantages** : Very simple
    + **Result** : Numerous networking-related options aren't supported yet, reproducing a "sidecar-like" interaction is **not possible at the moment**

+ Making the main app process launch the Dapr runtime (daprd) (see subdirectory : @TDB) 
    + **Advantages** : Compatible with non-containerized workloads 
    + **Result** : Although the "sidecar" is working, ASE does not allow for HTTP/2.0 (what GRPC is based on). However, in Dapr, Sidecar to sidecar communication must be over GRPC. Thus, **this won't work at the moment**.

+  Externalizing sidecars using [Azure Container Instances (ACI)](https://docs.microsoft.com/en-us/azure/container-instances/)
    + **Advantages** : A lot easier to see sidecar state
    + **Result** : This is the **chosen approach**. Externalizing sidecar allows for sidecar to sidecar communication to work without any problems. However, a sidecar should be using the same localhost interface as the process its helping. To run a sidecar is a separate service altogether, some proxies are used. This may have some performances impact (see [viability and performances considerations](#viability-and-performance-consideration)). As these helpers processes aren't at the main process side anymore, but more of a "satellite processes", they'll be called from now on satcars.


## Chosen solution

The chosen solution is to externalize sidecars. As said earlier, this specific approach is meant to circumvent the HTTP2.0/GRPC incompatibility of ASEs. To allow for "localhost forwarding", a simple nginx reverse proxy is used both on the sidecar side and ont he main app side. 

A normal Dapr [service invocation](https://docs.dapr.io/developing-applications/building-blocks/service-invocation/service-invocation-overview/) is made in this way:
![Dapr service invocation](./assets/images/dapr-service-invocation-overview.png)
Service A is calling service B:
 + _Service A_ is calling its Dapr sidecar (using `HTTP/GRPC` on __localhost:3500__)
 + _Service A_'s sidecar is resolving the name of _Service B_ to find its IP address (ore more precisely, **the IP address of its sidecar**) (using `mDNS by default`)
 + _Service A_'s sidecar is forwarding the request to _Service B_'s sidecar (using `GRPC only`)
 + _Service B_'s sidecar is forwarding the request to _Service B_ (using `HTTP/GRPC` on __localhost:[EXPOSED_APP_PORT]__)
 + (The result goes all the way back to _Service A_)

To reproduce the same workflow with externals sidecar, we have to tweak the architecture a bit :
![How it works](./assets/images/how-it-works.png)
_App1_ is calling _App2_:
 + _App 1_ is calling its Dapr sidecar using `HTTP` on __localhost:3500__. The HTTP call is then proxied to _satcar1_ by the Nginx process listening on __localhost:3500__.
 + _satcar1_ is resolving the name of _App2_ to find the IP address of _satcar2_ (which would normally be the same as the IP address of _App2_ but not in this case). mDNS can't be used on an ASE, so a **separate [Consul](https://www.consul.io/) instance** is used a name resolver using [Dapr's name resolver component](https://docs.dapr.io/reference/components-reference/supported-name-resolution/setup-nr-consul/). 
 + _satcar1_ is forwarding the request to _satcar2_ (using `GRPC only`)
 + _satcar2_ is forwarding the request to _App2_ (using `HTTP/GRPC` on __localhost:[EXPOSED_APP_PORT]__)
 + (The result goes all the way back to _App1_)


### Demo app
To test this new workflow, a Pub/Sub demo app is used. This demo app is actually the [hello-docker-compose sample](https://github.com/dapr/samples/tree/master/hello-docker-compose) of the Dapr repository. 

![Demo App](./assets/images/demo-app.png)

The Python app wants to publish a state. It does so by calling the `/neworder` method on the NodeJS app. The node app is then persisting the stae in the Redis statestore, using Dapr as a layer of abstraction. 
This demo app is demonstrating both service invocation and the use of [bindings](https://docs.dapr.io/developing-applications/building-blocks/bindings/bindings-overview/). 

There are 3 main components :
- Nodeapp
- Pythonapp
- Satcar [see Readme](src/using-satcars/satcar/README)


#### Running it locally
To run the sample app locally, you must have Docker and make installed. Then run :
```sh
# The OPTIMIZE flag can be set to 1. 
# This will reduce the container final size by compressing the binaries (when applicable). 
# This will however erase debug symbols, do not use it in development
make OPTIMIZE=0 run 
```
This will pull/build the necessary containers and start the apps.

You can then stop the containers with 

```sh
make stop
```

You can also push the nodeapp, pythonapp, satcar images to Dockerhub with the following command

```sh
make push DOCKERHUB_USERNAME=<YOUR_DOCKERHUB_USENAME>
```

#### Deploying it on azure 

To deploy the app on Azure (using Terraform), use the following commands :
```sh
cd deploy
terraform apply 
```

The deployment will last 3 hours or so (creating an ASE takes a long time). 


## Viability and performance consideration


@TDB