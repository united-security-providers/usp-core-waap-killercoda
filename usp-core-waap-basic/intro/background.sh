#!/bin/bash
#
# intro background script log available at /var/log/killercoda/background0_std(err|out).log

# variables
WAIT_SEC=15

# setup juiceshop web app
echo "$(date) : applying juiceshop web app..."
kubectl apply -f ~/.scenario_staging/juiceshop.yaml
echo "$(date) : waiting for juiceshop pod to be ready..."
kubectl wait pods juiceshop -n juiceshop --for='condition=Ready' --timeout=300s
echo "$(date) : wait ${WAIT_SEC}s..."
sleep $WAIT_SEC
echo "$(date) : juiceshop setup finished"
# setup core waap operator
# variables
export CORE_WAAP_VERSION=1.1.8
export CORE_WAAP_OP_VERSION=1.0.1
export CORE_WAAP_HELM_VERSION=1.0.2
export CONTAINER_REGISTRY=devuspregistry.azurecr.io
sleep $WAIT_SEC
echo "$(date) : login to helm registry..."
echo "RVkvOFNDMzdWWlo5VWsvSlZFcjRZK2pOSVAraGZiZ29pMmtaSE9DS3k1K0FDUkIrV015Yg==" | base64 -d | helm registry login ${CONTAINER_REGISTRY} --username killercoda --password-stdin
echo "$(date) : change to scenario_staging dir..."
cd ~/.scenario_staging/
echo "$(date) : prepare core waap operator setup..."
kubectl apply -f ./imagepullsecret.yaml
echo "$(date) : patch default serviceaccount in juiceshop namespace..."
kubectl patch serviceaccount default -n juiceshop -p '{"imagePullSecrets": [{"name": "devuspacr"}]}'
echo "$(date) : apply defined variables in helm-values template..."
envsubst < ./operator-helm-template.yaml > ./operator-helm-values.yaml
echo "$(date) : install operator via helm chart..."
helm install \
  usp-core-waap-operator \
  oci://${CONTAINER_REGISTRY}/helm/usp/core/waap/usp-core-waap-operator \
  --version ${CORE_WAAP_HELM_VERSION} \
  --values ./operator-helm-values.yaml
echo "$(date) : copy corewaap custom resouce to user home..."
cp ./juiceshop-core-waap.yaml ~
echo "$(date) : signal foreground script completion..."
touch /tmp/.operator_installed
echo "$(date) : core waap operator setup finished"
