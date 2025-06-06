#!/bin/bash

# SPDX-FileCopyrightText: 2025 United Security Providers AG, Switzerland
#
# SPDX-License-Identifier: GPL-3.0-only

#
# intro background script log available at /var/log/killercoda/background0_std(err|out).log

# variables
WAIT_SEC=5
BACKEND_NAMESPACE="juiceshop"
BACKEND_POD="juiceshop"
BACKEND_SETUP_FINISH="/tmp/.backend_installed"
OPERATOR_SETUP_FINISHED="/tmp/.operator_installed"
WAAP_SETUP_FINISH="/tmp/.waap_installed"
RC=99

# exports
export CORE_WAAP_HELM_VERSION="1.3.0-rc1"
export CONTAINER_REGISTRY="devuspregistry.azurecr.io"
export CONTAINER_BASE_PATH="usp/core/waap/demo"

# Part 1: setup backend web app
echo "$(date) : applying backend web app..."
kubectl apply -f ~/.scenario_staging/${BACKEND_POD}.yaml
echo "$(date) : waiting for ${BACKEND_NAMESPACE}/${BACKEND_POD} to be ready..."
kubectl wait pods ${BACKEND_POD} -n ${BACKEND_NAMESPACE} --for='condition=Ready' --timeout=300s
echo "$(date) : wait ${WAIT_SEC}s..."
sleep $WAIT_SEC
touch $BACKEND_SETUP_FINISH && echo "$(date) : wrote file $BACKEND_SETUP_FINISH to indicate backend setup completion to foreground process"
echo "$(date) : backend setup finished"
# Part 2: setup core waap operator
sleep $WAIT_SEC
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
echo "$(date) : core waap operator setup finished"
touch $OPERATOR_SETUP_FINISHED && echo "$(date) : wrote file $OPERATOR_SETUP_FINISHED to indicate operator installation setup completion to foreground process"
# Part 3: configure core waap instance
echo "$(date) : applying corewaap instance config..."
kubectl apply -f ./${BACKEND_POD}-core-waap-initial.yaml
echo "$(date) : waiting for corewaap instance to be ready..."
RC=99
while [ $RC -gt 0 ]; do
  sleep 2
  kubectl wait pods -l app.kubernetes.io/name=usp-core-waap -n ${BACKEND_NAMESPACE} --for='condition=Ready' --timeout=10s
  RC=$?
done
echo "$(date) : corewaap instance found in condition ready"
echo "$(date) : creating portforwarding via corewaap..."
RC=99
PORT_FORWARD_PID="/tmp/.core-waap-port-forward-pid"
while [ $RC -gt 0 ]; do
  clear
  pkill -F $PORT_FORWARD_PID || true
  echo "$(date) : ...setting up port-forwarding and testing access..."
  nohup kubectl -n ${BACKEND_NAMESPACE} port-forward svc/${BACKEND_POD}-usp-core-waap 80:8080 --address 0.0.0.0 >/dev/null &
  echo $! > $PORT_FORWARD_PID
  sleep 3
  curl -svo /dev/null http://localhost:80
  RC=$?
done
# Signal work done to foreground waiting scripts
touch $WAAP_SETUP_FINISH && echo "$(date) : wrote file $WAAP_SETUP_FINISH to indicate waap setup completion to foreground process"