apiVersion: dapr.io/v1alpha1
kind: Component
metadata:
  name: statestore
spec:
  type: state.redis
  version: v1
  metadata:
  - name: redisHost
    value: ${REDIS_HOST}:${REDIS_PORT}
  - name: redisPassword
    value: ""