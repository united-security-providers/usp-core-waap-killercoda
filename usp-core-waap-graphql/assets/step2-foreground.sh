#!/bin/bash

# SPDX-FileCopyrightText: 2025 United Security Providers AG, Switzerland
#
# SPDX-License-Identifier: GPL-3.0-only

rm $0

clear

echo -n "Installing USP Core WAAP Operator..."
while [ ! -f /tmp/.operator_installed ]; do
  echo -n '.'
  sleep 1;
done;
echo " done"
echo
echo "*** Scenario ready ***"
