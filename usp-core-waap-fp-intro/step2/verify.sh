#!/bin/bash

# SPDX-FileCopyrightText: 2025 United Security Providers AG, Switzerland
#
# SPDX-License-Identifier: GPL-3.0-only

LOGS=$(kubectl logs -n juiceshop -l app.kubernetes.io/name=usp-core-waap | grep "coraza-vm.*/socket.io" | wc -l)
test $LOGS -eq 0
