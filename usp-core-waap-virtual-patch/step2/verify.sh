#!/bin/bash

kubectl logs \
  -n prometheus \
  -l app.kubernetes.io/name=usp-core-waap \
  --tail=-1 \
  | grep "\[critical\]\[golang\].*/debug/pprof" \
  | sed -e 's/\[.*\] {/{/' \
  | jq --exit-status \
  'select(."request.path" == "/debug/pprof" and ."crs.violated_rule".id > 299999 and ."crs.violated_rule".id < 400000)'
