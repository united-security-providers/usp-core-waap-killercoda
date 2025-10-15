#!/bin/bash

# SPDX-FileCopyrightText: 2025 United Security Providers AG, Switzerland
#
# SPDX-License-Identifier: GPL-3.0-only

rm $0

clear

echo -n "Installing LLDAP backend application..."
while [ ! -f /tmp/.backend_installed ]; do
  echo -n '.'
  sleep 1;
done;
LLDAP_TOKEN=$(curl -s -X POST -H 'Content-Type: application/json' http://localhost:8080/auth/simple/login -d '{"username":"admin", "password":"insecure"}' | jq -r '.token')
export LLDAP_TOKEN
if [ -n "$LLDAP_TOKEN" ]; then
  echo " done"
  echo
  echo "*** Scenario ready ***"
else
  echo " failed"
  echo
  echo "ERROR: LLDAP backend setup failed - please restart the scenario (if consistent report this error on scenario overview page)"
  exit 1
fi
