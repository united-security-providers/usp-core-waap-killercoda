#!/bin/bash

# SPDX-FileCopyrightText: 2025 United Security Providers AG, Switzerland
#
# SPDX-License-Identifier: GPL-3.0-only

SOCKET_IO_LOGS=$(kubectl logs -n juiceshop -l app.kubernetes.io/name=usp-core-waap | grep "coraza-vm.*/socket.io" | wc -l)
SQLI_LOGS=$(kubectl logs -n juiceshop -l app.kubernetes.io/name=usp-core-waap --tail=-1 | grep APPLICATION-ATTACK-SQLI | wc -l)
test $SOCKET_IO_LOGS -eq 0 && test $SQLI_LOGS -gt 1
