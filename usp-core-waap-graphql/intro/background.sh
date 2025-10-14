#!/bin/bash

# SPDX-FileCopyrightText: 2025 United Security Providers AG, Switzerland
#
# SPDX-License-Identifier: GPL-3.0-only

#
# intro background script log available at /var/log/killercoda/background0_std(err|out).log

# variables
WAIT_SEC=5
BACKEND_NAMESPACE="lldap"
BACKEND_POD="lldap"
BACKEND_SVC="lldap"
BACKEND_PORT="17170"
BACKEND_SETUP_FINISH="/tmp/.backend_installed"
OPERATOR_SETUP_FINISHED="/tmp/.operator_installed"
PORT_FORWARD_PID="/tmp/.backend-port-forward-pid"
RC=99

# exports
export CORE_WAAP_HELM_VERSION="1.4.0"
export CONTAINER_REGISTRY="devuspregistry.azurecr.io"
export CONTAINER_BASE_PATH="usp/core/waap/demo"

# Part 1: setup lldap backend (https://github.com/lldap/lldap / https://artifacthub.io/packages/helm/alexmorbo-lldap/lldap)
echo "$(date) : installing lldap backend app..."
helm upgrade --install \
  --create-namespace \
  -n ${BACKEND_NAMESPACE} \
  ${BACKEND_POD} \
  oci://ghcr.io/alexmorbo/helm-charts/lldap \
  --set 'secret.lldapUserPass=insecure' || exit 1
echo "$(date) : waiting for ${BACKEND_NAMESPACE}/${BACKEND_POD} to be ready..."
kubectl wait pods -l app.kubernetes.io/name=lldap -n ${BACKEND_NAMESPACE} --for='condition=Ready' --timeout=300s
echo "$(date) : wait ${WAIT_SEC}s..."
sleep $WAIT_SEC
while [ ${RC:-99} -gt 0 ]; do
  pkill -F $PORT_FORWARD_PID || true
  echo "$(date) : ...setting up port-forwarding and testing access..."
  nohup kubectl port-forward -n ${BACKEND_NAMESPACE} svc/${BACKEND_SVC} 8080:$BACKEND_PORT --address 0.0.0.0 >/dev/null &
  echo $! > $PORT_FORWARD_PID
  sleep 3
  curl -svo /dev/null http://localhost:8080
  RC=$?
done
echo "$(date) : query JWT authentication token..."
LLDAP_TOKEN=$(curl -s -X POST -H 'Content-Type: application/json' http://localhost:8080/auth/simple/login -d '{"username":"admin", "password":"insecure"}' | jq -r '.token')
export LLDAP_TOKEN
touch $BACKEND_SETUP_FINISH && echo "$(date) : wrote file $BACKEND_SETUP_FINISH to indicate backend setup completion to foreground process"
echo "$(date) : backend setup finished"
# Part 2: setup core waap operator
echo "$(date) : login to helm registry..."
echo "RVkvOFNDMzdWWlo5VWsvSlZFcjRZK2pOSVAraGZiZ29pMmtaSE9DS3k1K0FDUkIrV015Yg==" | base64 -d | helm registry login ${CONTAINER_REGISTRY} --username killercoda --password-stdin
echo "$(date) : change to scenario_staging dir..."
cd ~/.scenario_staging/ || exit 1
echo "$(date) : prepare core waap operator setup..."
kubectl apply -f ./imagepullsecret.yaml
echo "$(date) : patch default serviceaccount in ${BACKEND_NAMESPACE} namespace..."
kubectl patch serviceaccount default -n ${BACKEND_NAMESPACE} -p '{"imagePullSecrets": [{"name": "devuspacr"}]}'
echo "$(date) : apply defined variables in helm-values template..."
envsubst < ./operator-helm-template.yaml > ./operator-helm-values.yaml
echo "$(date) : install operator via helm chart..."
helm install \
  usp-core-waap-operator \
  oci://${CONTAINER_REGISTRY}/helm/usp/core/waap/usp-core-waap-operator \
  --version ${CORE_WAAP_HELM_VERSION} \
  --values ./operator-helm-values.yaml \
  --namespace usp-core-waap-operator
echo "$(date) : copy corewaap custom resouces to user home..."
cp ./${BACKEND_POD}-core-waap.yaml ~
cp ./${BACKEND_POD}-schema.graphql ~
echo "$(date) : core waap operator setup finished"
touch $OPERATOR_SETUP_FINISHED && echo "$(date) : wrote file $OPERATOR_SETUP_FINISHED to indicate operator installation setup completion to foreground process"
