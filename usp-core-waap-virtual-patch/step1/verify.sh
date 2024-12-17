#!/bin/bash

kubectl -n prometheus logs -l app.kubernetes.io/name=prometheus,app.kubernetes.io/component=server -c prometheus-server | grep '/debug/pprof'
