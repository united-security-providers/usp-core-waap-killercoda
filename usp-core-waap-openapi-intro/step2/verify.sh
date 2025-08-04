#!/bin/bash

# SPDX-FileCopyrightText: 2025 United Security Providers AG, Switzerland
#
# SPDX-License-Identifier: GPL-3.0-only

kubectl logs \
  -l app.kubernetes.io/name=usp-core-waap \
  -n petstore \
  -c traffic-processor-openapi-petstore-v3 \
  | grep 'is not a valid number'
