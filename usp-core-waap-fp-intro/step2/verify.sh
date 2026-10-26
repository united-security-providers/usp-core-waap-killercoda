#!/bin/bash

# SPDX-FileCopyrightText: 2025 United Security Providers AG, Switzerland
#
# SPDX-License-Identifier: GPL-3.0-only

# exception must be configured and no socket.io block logged since last config reload
kubectl get corewaapservice juiceshop-usp-core-waap -n juiceshop \
  -o jsonpath='{.spec.coraza.crs.requestRuleExceptions[*].ruleIds}' | grep -q 920420 || exit 1
LOGS=$(kubectl logs -n juiceshop -l app.kubernetes.io/name=usp-core-waap-proxy --tail=-1 \
  | tac | sed '/add\/update listener/q' \
  | grep -c '\[critical\]\[golang\].*/socket\.io')
test "$LOGS" -eq 0
