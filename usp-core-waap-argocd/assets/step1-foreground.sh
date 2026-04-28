#!/bin/bash

# SPDX-FileCopyrightText: 2026 United Security Providers AG, Switzerland
#
# SPDX-License-Identifier: GPL-3.0-only

rm $0

BACKEND_SETUP_ARGOCD="/tmp/.backend_argocd_installed"
BACKEND_SETUP_GOGS="/tmp/.backend_gogs_installed"
BACKEND_SETUP_WAAP_OPERATOR="/tmp/.backend_corewaap_operator_installed"
BACKEND_SETUP_DEMO_APP="/tmp/.backend_demo_app_installed"
BACKEND_SETUP_FINISH="/tmp/.backend_installed"

log_info() {
  echo
  echo "$1"
}

clear

log_info "Installing ArgoCD application..."
while [ ! -f ${BACKEND_SETUP_ARGOCD} ]; do
  echo -n '.'
  sleep 1;
done;
log_info "Installing Gogs application..."
while [ ! -f ${BACKEND_SETUP_GOGS} ]; do
  echo -n '.'
  sleep 1;
done;
log_info "Installing WAAP Operator..."
while [ ! -f ${BACKEND_SETUP_WAAP_OPERATOR} ]; do
  echo -n '.'
  sleep 1;
done;
log_info "Installing Demo application..."
while [ ! -f ${BACKEND_SETUP_DEMO_APP} ]; do
  echo -n '.'
  sleep 1;
done;
log_info "Finalizing scenario setup..."
while [ ! -f ${BACKEND_SETUP_FINISH} ]; do
  echo -n '.'
  sleep 1;
done;
log_info "*** Scenario ready ***"
