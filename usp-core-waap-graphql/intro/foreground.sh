#!/bin/bash

# SPDX-FileCopyrightText: 2025 United Security Providers AG, Switzerland
#
# SPDX-License-Identifier: GPL-3.0-only

FILE=~/.scenario_staging/step1-foreground.sh; while ! test -f ${FILE}; do clear; sleep 0.1; done; bash ${FILE}

LLDAP_TOKEN=$(curl -s -X POST -H 'Content-Type: application/json' http://localhost:8080/auth/simple/login -d '{"username":"admin", "password":"insecure"}' | jq -r '.token')
export LLDAP_TOKEN

if [ -z "$LLDAP_TOKEN" ]; then
  echo "ERROR: LLDAP backend setup failed - please restart the scenario (if consistent report this error on scenario overview page)"
fi
