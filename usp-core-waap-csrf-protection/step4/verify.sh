#!/bin/bash

# SPDX-FileCopyrightText: 2025 United Security Providers AG, Switzerland
#
# SPDX-License-Identifier: GPL-3.0-only

kubectl logs \
  -n juiceshop \
  -l app.kubernetes.io/name=usp-core-waap-proxy \
  --tail=-1 \
  | grep '\[access\]' \
  | grep -q 'response.details="csrf_origin_mismatch"'
