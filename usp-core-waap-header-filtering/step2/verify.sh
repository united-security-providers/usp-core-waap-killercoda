#!/bin/bash

# SPDX-FileCopyrightText: 2025 United Security Providers AG, Switzerland
#
# SPDX-License-Identifier: GPL-3.0-only

kubectl logs \
  -n nextjs \
  -l app.kubernetes.io/name=usp-core-waap \
  --tail=-1 \
  | grep "\[critical\]\[golang\].*/debug/pprof" \
  | sed -e 's/\[.*\] {/{/' \
  | jq --exit-status \
  'select(."request.path" == "/debug/pprof" and ."crs.violated_rule".id > 299999 and ."crs.violated_rule".id < 400000)'
