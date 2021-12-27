# Node app

Simple app receiving a JSON payload and saving it in a state store.

## API

- GET /order -> Retrieve the last saved state
- POST /neworder -> Save a new state (= body of the request)

## Configuration

This app **needs** the following env variables:

- **DAPR_HOST** : IP/URL of the DAPR sidecar

These other env variables can be set but are not needed:

- **NODE_DAPR_HTTP_HOST** : Sidecar host as seen by the Node application. Defaults to localhost.
- **NODE_DAPR_HTTP_PORT** : Sidecar port as seen by the Node application. Defaults to 3500.

These two variables exists for debugging purpose and shouldn't be changed. All calls to localhost:3500 will be catched by the Nginx process and sent to the DAPR_HOST
