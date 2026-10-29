#!/bin/bash

# SPDX-FileCopyrightText: 2025 United Security Providers AG, Switzerland
#
# SPDX-License-Identifier: GPL-3.0-only

kubectl logs \
  -l app.kubernetes.io/name=usp-core-waap-proxy \
  -n petstore \
  --tail=-1 \
  | grep -q 'is not a valid number'
