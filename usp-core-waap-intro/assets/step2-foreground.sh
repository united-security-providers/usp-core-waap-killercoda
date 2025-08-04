#!/bin/bash

# SPDX-FileCopyrightText: 2025 United Security Providers AG, Switzerland
#
# SPDX-License-Identifier: GPL-3.0-only

rm $0

clear

echo -n "Waiting for USP Core WAAP operator installation to be finished..."
while [ ! -f /tmp/.operator_installed ]; do
  echo -n '.'
  sleep 1;
done;
kubectl wait pods --all -n usp-core-waap-operator --for='condition=Ready' --timeout=60s &>/dev/null || echo "ERROR: core waap operator installation did not succeed!"
echo " done"

echo
