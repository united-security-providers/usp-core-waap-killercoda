#!/bin/bash

# SPDX-FileCopyrightText: 2026 United Security Providers AG, Switzerland
#
# SPDX-License-Identifier: GPL-3.0-only

rm $0

BACKEND_SETUP_KYVERNO="/tmp/.backend_kyverno_installed"

log_install() {
  echo
  echo -n "$1"
}

log_info() {
  echo -e "$1"
}

clear

log_install "Installing Kyverno"
while [ ! -f ${BACKEND_SETUP_KYVERNO} ]; do
  echo -n '.'
  sleep 1;
done;
log_info "\n\n*** Scenario ready ***"
