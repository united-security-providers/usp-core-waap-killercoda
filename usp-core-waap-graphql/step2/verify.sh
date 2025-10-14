#!/bin/bash

# SPDX-FileCopyrightText: 2025 United Security Providers AG, Switzerland
#
# SPDX-License-Identifier: GPL-3.0-only

kubectl logs \
  -n lldap \
  -l app.kubernetes.io/name=usp-core-waap \
  --tail=-1 \
  | grep "/api/hello"
