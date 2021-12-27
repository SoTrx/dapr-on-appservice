# Python app

Infinite loop sending a new state each second

## API

- GET /order -> Retrieve the last saved state
- POST /neworder -> Save a new state (= body of the request)

## Configuration

This app **needs** the following env variables:

- **DAPR_HOST** : IP/URL of the DAPR sidecar
- **NODE_APP_ID** : Name of the node application as declared by Dapr. Default is nodeapp.

These other env variables can be set but are not needed:

- **MPROC_DAPR_HTTP_HOST** : Sidecar host as seen by the Node application. Defaults to localhost.
- **MPROC_DAPR_HTTP_PORT** : Sidecar port as seen by the Node application. Defaults to 3500.

These two variables exists for debugging purpose and shouldn't be changed. All calls to localhost:3500 will be catched by the Nginx process and sent to the DAPR_HOST
