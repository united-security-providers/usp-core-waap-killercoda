#!/bin/bash

# SPDX-FileCopyrightText: 2025 United Security Providers AG, Switzerland
#
# SPDX-License-Identifier: GPL-3.0-only

# Redirect stdout/stderr to log file
exec > /var/log/killercoda/background_step3_stdout.log
exec 2> /var/log/killercoda/background_step3_stderr.log

##################################################
# Functions
##################################################

log_info() {
  echo "****************************************************************"
  echo "*** $(date) : $1"
  echo "****************************************************************"
}

log_error() {
  echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
  echo "!!! $(date) : ERROR: $1"
  echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
}

wait_for_url() {
  local url=$1
  local max_retries=${2:-30}
  local retry_interval=5

  for ((i=1; i<=max_retries; i++)); do
    if curl --fail -s "$url" > /dev/null; then
      log_info "URL $url is accessible"
      return 0
    else
      log_info "Waiting for URL $url to be accessible (attempt $i/$max_retries)..."
      sleep $retry_interval
    fi
  done

  log_error "URL $url is not accessible after $max_retries attempts"
  return 1
}

##################################################
# Initialization
##################################################
log_info "initializing variables..."
_KILLERCODA_NODE_IP="172.30.1.2"
WAIT_SEC=2
BACKEND_NAMESPACE="juiceshop"
BACKEND_POD="juiceshop"
BACKEND_SETUP_FINISH="/tmp/.backend_installed"
OPERATOR_SETUP_FINISHED="/tmp/.operator_installed"


log_info "waiting for corewaap instance to be created/ready..."
RC=99
while [ $RC -gt 0 ]; do
  sleep $WAIT_SEC
  kubectl wait pods -l app.kubernetes.io/name=usp-core-waap-proxy -n juiceshop --for='condition=Ready' --timeout=10s
  RC=$?
done
log_info "corewaap instance found in condition ready"

log_info "creating node-port svc for core waap..."
cat << EOF | kubectl apply -f -
kind: Service
apiVersion: v1
metadata:
  name: juiceshop-waap-nodeport
  namespace: juiceshop
spec:
  type: NodePort
  selector:
    app.kubernetes.io/instance: juiceshop-usp-core-waap
  ports:
  - name: http
    port: 8080
    targetPort: 8080
    nodePort: 30090
EOF

wait_for_url "http://${_KILLERCODA_NODE_IP}:30090" || log_error "core waap instance is not accessible after waiting for 30 attempts"
log_info "core waap instance is accessible via node-port"

log_info "background script finished (last seen RC=$?)"
