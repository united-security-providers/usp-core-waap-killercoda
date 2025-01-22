#!/bin/bash

kubectl logs \
  -l app.kubernetes.io/name=usp-core-waap \
  -n petstore \
  -c traffic-processor-openapi-petstore-v3 \
  | grep 'is not a valid number'
