#!/bin/bash

# SPDX-FileCopyrightText: 2025 United Security Providers AG, Switzerland
#
# SPDX-License-Identifier: GPL-3.0-only

rm $0

clear

echo -n "Installing Juice Shop backend and attacker website..."
while [[ ! -f /tmp/.backend_installed ||  ! -f /tmp/.attacker_installed ]]; do
  echo -n '.'
  sleep 1;
done;
echo " done"
echo
echo "*** Scenario ready ***"
