#!/bin/bash

# SPDX-FileCopyrightText: 2025 United Security Providers AG, Switzerland
#
# SPDX-License-Identifier: GPL-3.0-only

#
# intro background script log available at /var/log/killercoda/background0_std(err|out).log

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
WAIT_SEC=5
BACKEND_NAMESPACE="juiceshop"
BACKEND_POD="juiceshop"
BACKEND_SETUP_FINISH="/tmp/.backend_installed"
OPERATOR_SETUP_FINISHED="/tmp/.operator_installed"

# exports
export CORE_WAAP_HELM_VERSION="2.0.0"
export CONTAINER_REGISTRY="devuspregistry.azurecr.io"
export CONTAINER_BASE_PATH="usp/core/waap/demo"

##################################################
# Part 1: setup backend web app
##################################################
log_info "applying backend web app..."
kubectl apply -f ~/.scenario_staging/${BACKEND_POD}.yaml || log_error "failed to apply backend web app manifest"
log_info "waiting for ${BACKEND_NAMESPACE}/${BACKEND_POD} to be ready..."
kubectl wait pods ${BACKEND_POD} -n ${BACKEND_NAMESPACE} --for='condition=Ready' --timeout=300s \
  || log_error "pod ${BACKEND_POD} in namespace ${BACKEND_NAMESPACE} is not ready after waiting for 300s"
wait_for_url "http://${_KILLERCODA_NODE_IP}:30080" || log_error "backend web app is not accessible after waiting for 30 attempts"
log_info "backend web app is accessible"
touch $BACKEND_SETUP_FINISH && log_info "wrote file $BACKEND_SETUP_FINISH to indicate backend setup completion to foreground process"
log_info "backend setup finished"

##################################################
# Part 2: setup core waap operator
##################################################
sleep $WAIT_SEC
log_info "login to helm registry..."
echo "RVkvOFNDMzdWWlo5VWsvSlZFcjRZK2pOSVAraGZiZ29pMmtaSE9DS3k1K0FDUkIrV015Yg==" | base64 -d | helm registry login ${CONTAINER_REGISTRY} --username killercoda --password-stdin
log_info "change to scenario_staging dir..."
cd ~/.scenario_staging/ || exit 1
log_info "prepare core waap operator setup..."
kubectl apply -f ./imagepullsecret.yaml
log_info "patch default serviceaccount in ${BACKEND_NAMESPACE} namespace..."
kubectl patch serviceaccount default -n ${BACKEND_NAMESPACE} -p '{"imagePullSecrets": [{"name": "devuspacr"}]}'
log_info "apply defined variables in helm-values template..."
envsubst < ./operator-helm-template.yaml > ./operator-helm-values.yaml
log_info "install operator via helm chart..."
helm install \
  usp-core-waap-operator \
  oci://${CONTAINER_REGISTRY}/helm/usp/core/waap/usp-core-waap-operator \
  --version ${CORE_WAAP_HELM_VERSION} \
  --values ./operator-helm-values.yaml \
  --namespace usp-core-waap-operator
log_info "copy corewaap custom resouces to user home..."
cp ./${BACKEND_POD}-core-waap.yaml ~
log_info "signal foreground script completion..."
touch $OPERATOR_SETUP_FINISHED
log_info "core waap operator setup finished"
