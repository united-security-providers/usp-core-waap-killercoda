#!/bin/bash

# SPDX-FileCopyrightText: 2025 United Security Providers AG, Switzerland
#
# SPDX-License-Identifier: GPL-3.0-only

# exception must be configured and no socket.io block logged since last config reload
# (compares timestamps, as waf and listener log lines are not written in strict order)
kubectl get corewaapservice juiceshop-usp-core-waap -n juiceshop \
  -o jsonpath='{.spec.coraza.crs.requestRuleExceptions[*].ruleIds}' | grep -q 920420 || exit 1
LOGS=$(kubectl logs -n juiceshop -l app.kubernetes.io/name=usp-core-waap-proxy --tail=-1 \
  | awk -F'[][]' '
    /add\/update listener/ { if ($2 > reload) reload = $2 }
    /\[coraza-waf\].*uri="\/socket\.io/ { hits[++n] = $2 }
    END { c = 0; for (i = 1; i <= n; i++) if (hits[i] > reload) c++; print c }')
test "$LOGS" -eq 0
