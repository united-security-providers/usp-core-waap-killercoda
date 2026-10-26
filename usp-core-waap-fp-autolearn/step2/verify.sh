#!/bin/bash

# SPDX-FileCopyrightText: 2025 United Security Providers AG, Switzerland
#
# SPDX-License-Identifier: GPL-3.0-only

# no socket.io block logged since last config reload, sqli still blocked
# (compares timestamps, as waf and listener log lines are not written in strict order)
SOCKET_IO_LOGS=$(kubectl logs -n juiceshop -l app.kubernetes.io/name=usp-core-waap-proxy --tail=-1 \
  | awk -F'[][]' '
    /add\/update listener/ { if ($2 > reload) reload = $2 }
    /\[coraza-waf\].*uri="\/socket\.io/ { hits[++n] = $2 }
    END { c = 0; for (i = 1; i <= n; i++) if (hits[i] > reload) c++; print c }')
SQLI_LOGS=$(kubectl logs -n juiceshop -l app.kubernetes.io/name=usp-core-waap-proxy --tail=-1 | grep APPLICATION-ATTACK-SQLI | wc -l)
test $SOCKET_IO_LOGS -eq 0 && test $SQLI_LOGS -gt 1
