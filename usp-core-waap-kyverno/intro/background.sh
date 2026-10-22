#!/bin/bash

# SPDX-FileCopyrightText: 2026 United Security Providers AG, Switzerland
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
_KILLERCODA_NODE_IP="172.30.2.2"
BACKEND_SETUP_FINISH="/tmp/.backend_installed"
BACKEND_SETUP_KYVERNO="/tmp/.backend_kyverno_installed"
BACKEND_SETUP_WAAP_OPERATOR="/tmp/.backend_corewaap_operator_installed"
COREWAAP_HELM_CHART="helm/usp/core/waap/usp-core-waap-operator"
COREWAAP_HELM_VERSION="2.1.2"
COREWAAP_OPERATOR_IMAGE_PATH="usp/core/waap/demo/usp-core-waap-operator"
COREWAAP_OPERATOR_NAMESPACE="usp-core-waap-operator"
COREWAAP_PROXY_IMAGE_PATH="usp/core/waap/demo/usp-core-waap-proxy-demo"
COREWAAP_REGISTRY_SERVER="devuspregistry.azurecr.io"
COREWAAP_REGISTRY_USER="killercoda"
HTTPBIN_NAMESPACE="httpbin"
HTTPBIN_NODEPORT=30081
JUICESHOP_NAMESPACE="juiceshop"
JUICESHOP_NODEPORT=30080
KYVERNO_HELM_VERSION="3.9.2"
KYVERNO_NAMESPACE="kyverno"
KYVERNO_POLICY_FILE="kyverno_policy.yaml"


log_info "change to scenario_staging dir..."
cd ~/.scenario_staging/ || exit 1

##################################################
# Part 1: setup kyverno
##################################################
log_info "installing kyverno..."

# kyverno helm installation
# https://kyverno.io/docs/installation/installation/
helm repo add kyverno https://kyverno.github.io/kyverno/ \
  || log_error "failed to add kyverno helm repository"
helm repo update \
  || log_error "failed to update helm repositories after adding kyverno helm repository"
helm install kyverno kyverno/kyverno -n ${KYVERNO_NAMESPACE} --create-namespace \
  --version ${KYVERNO_HELM_VERSION} --wait --timeout 300s \
  || log_error "failed to install kyverno via helm in namespace ${KYVERNO_NAMESPACE}"

##################################################
# Part 2: USP Core WAAP Operator setup
##################################################
log_info "login to helm registry..."
echo "RVkvOFNDMzdWWlo5VWsvSlZFcjRZK2pOSVAraGZiZ29pMmtaSE9DS3k1K0FDUkIrV015Yg==" \
  | base64 -d \
  | helm registry login ${COREWAAP_REGISTRY_SERVER} --username ${COREWAAP_REGISTRY_USER} --password-stdin \
  || log_error "failed to login to helm registry ${COREWAAP_REGISTRY_SERVER} with user ${COREWAAP_REGISTRY_USER}"

log_info "prepare core waap operator setup..."
kubectl create namespace ${COREWAAP_OPERATOR_NAMESPACE} \
  || log_error "failed to create namespace ${COREWAAP_OPERATOR_NAMESPACE} for core waap operator"
kubectl apply -f ./imagepullsecret.yaml -n ${COREWAAP_OPERATOR_NAMESPACE} \
  || log_error "failed to apply imagepullsecret for core waap operator"

log_info "patch default serviceaccount in ${COREWAAP_OPERATOR_NAMESPACE} namespace..."
kubectl patch serviceaccount default -n ${COREWAAP_OPERATOR_NAMESPACE} -p '{"imagePullSecrets": [{"name": "devuspacr"}]}' \
  || log_error "failed to patch default serviceaccount in ${COREWAAP_OPERATOR_NAMESPACE} namespace"

log_info "apply defined variables in helm-values template..."
export COREWAAP_OPERATOR_IMAGE_PATH
export COREWAAP_PROXY_IMAGE_PATH
export COREWAAP_REGISTRY_SERVER
envsubst < ./operator-helm-template.yaml > ./operator-helm-values.yaml || log_error "failed to apply defined variables in helm-values template"

log_info "install operator via helm chart..."
helm install \
  usp-core-waap-operator \
  oci://${COREWAAP_REGISTRY_SERVER}/${COREWAAP_HELM_CHART} \
  --version ${COREWAAP_HELM_VERSION} \
  --namespace ${COREWAAP_OPERATOR_NAMESPACE} \
  --values ./operator-helm-values.yaml \
  || log_error "failed to install operator using chart ${COREWAAP_HELM_CHART} version ${COREWAAP_HELM_VERSION} in namespace ${COREWAAP_OPERATOR_NAMESPACE}"

# apply the policy once the CoreWaapService CRD it targets is established
kubectl wait crd/corewaapservices.waap.core.u-s-p.ch --for=condition=Established --timeout=120s \
  || log_error "core waap CRD not established after waiting for 120s"

log_info "installing kyverno policies for core waap..."
kubectl apply -f ${KYVERNO_POLICY_FILE} \
  || log_error "failed to apply kyverno policies from file ${KYVERNO_POLICY_FILE}"

touch ${BACKEND_SETUP_KYVERNO} && log_info "wrote file $BACKEND_SETUP_KYVERNO to indicate kyverno installation completion to foreground process"
touch ${BACKEND_SETUP_WAAP_OPERATOR} && log_info "wrote file $BACKEND_SETUP_WAAP_OPERATOR to indicate core waap operator setup completion to foreground process"

##################################################
# Part 3: Backend web app setup
##################################################

log_info "installing backend web app juiceshop at http://${_KILLERCODA_NODE_IP}:${JUICESHOP_NODEPORT}..."
kubectl create namespace ${JUICESHOP_NAMESPACE} \
  || log_error "failed to create namespace ${JUICESHOP_NAMESPACE} for backend web app"
kubectl apply -f ./imagepullsecret.yaml -n ${JUICESHOP_NAMESPACE} \
  || log_error "failed to apply imagepullsecret for backend web app in namespace ${JUICESHOP_NAMESPACE}"
kubectl apply -f ./backend_juiceshop.yaml -n ${JUICESHOP_NAMESPACE} \
  || log_error "failed to apply backend web app manifest for juiceshop in namespace ${JUICESHOP_NAMESPACE}"
kubectl patch serviceaccount default -n ${JUICESHOP_NAMESPACE} -p '{"imagePullSecrets": [{"name": "devuspacr"}]}' \
  || log_error "failed to patch default serviceaccount in ${JUICESHOP_NAMESPACE} namespace"
wait_for_url "http://${_KILLERCODA_NODE_IP}:${JUICESHOP_NODEPORT}" \
  || log_error "backend web app is not accessible at http://${_KILLERCODA_NODE_IP}:${JUICESHOP_NODEPORT} after waiting for 30 attempts"

log_info "installing backend web app httpbin at http://${_KILLERCODA_NODE_IP}:${HTTPBIN_NODEPORT}..."
kubectl create namespace ${HTTPBIN_NAMESPACE} \
  || log_error "failed to create namespace ${HTTPBIN_NAMESPACE} for backend web app"
kubectl apply -f ./imagepullsecret.yaml -n ${HTTPBIN_NAMESPACE} \
  || log_error "failed to apply imagepullsecret for backend web app in namespace ${HTTPBIN_NAMESPACE}"
kubectl apply -f ./backend_httpbin.yaml -n ${HTTPBIN_NAMESPACE} \
  || log_error "failed to apply backend web app manifest for httpbin in namespace ${HTTPBIN_NAMESPACE}"
kubectl patch serviceaccount default -n ${HTTPBIN_NAMESPACE} -p '{"imagePullSecrets": [{"name": "devuspacr"}]}' \
  || log_error "failed to patch default serviceaccount in ${HTTPBIN_NAMESPACE} namespace"
wait_for_url "http://${_KILLERCODA_NODE_IP}:${HTTPBIN_NODEPORT}" \
  || log_error "backend web app is not accessible at http://${_KILLERCODA_NODE_IP}:${HTTPBIN_NODEPORT} after waiting for 30 attempts"

##################################################
# Finalization: signal setup complete to foreground script
##################################################
log_info "removing local imagepullsecret.yaml..."
rm -f ~/.scenario_staging/imagepullsecret.yaml || log_error "failed to remove local imagepullsecret.yaml"
touch $BACKEND_SETUP_FINISH && log_info "wrote file $BACKEND_SETUP_FINISH to indicate backend setup completion to foreground process"
log_info "backend setup finished"
