#!/bin/bash

kubectl -n petstore exec pod/petstore -- /bin/bash -c "grep -E 'GET /api/pet/cat1 .*' /var/log/*-requests.log"
