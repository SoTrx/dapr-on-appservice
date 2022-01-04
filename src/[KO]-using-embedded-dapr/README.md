# KO demo : embedding Dapr

## Idea

Using a docker-compose file showed that sidecars can't be used in an idiomatic way. So this time around, the main app and Dapr will both use the same container, sharing their localhost interface.

## Structure

The `node` and `python` folders are untouched version of the [hello-docker-compose sample](https://github.com/dapr/samples/tree/master/hello-docker-compose) in Dapr's repository.

The `node-with-dapr` and `python-with-dapr` folders are versions embedding daprd into the container. For each folder, the `entrypoint.sh` both start the app and the dapr runtime. At the app is started last, this would ensure that both the main app and the sidecar restart when the app dies.

Nginx Reverse proxies are also used to make a GRPC-pass proxy to the dapr runtime. 

## Result

Although this approach solves the **main app to sidecar** communication problem of the docker-compose approach, once again, as App Service is not compatible with HTTP/2.0, sidecars won't be able to communicate has GRPC calls will be terminated. 

As a result, this approach is a no go.

