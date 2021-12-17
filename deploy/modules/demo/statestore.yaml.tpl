apiVersion: dapr.io/v1alpha1
kind: Component
metadata:
  name: pubsub
spec:
  type: pubsub.redis
  version: v1
  metadata:
  - name: redisHost
    value: ${REDIS_HOST}:${REDIS_PORT}
  - name: redisPassword
    value: ""