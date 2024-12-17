#!/bin/bash

kubectl -n prometheus logs pod/prometheus-usp-core-waap | grep '/debug/pprof'
