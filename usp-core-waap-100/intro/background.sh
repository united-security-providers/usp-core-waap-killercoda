#!/bin/bash
#
# intro background script log available at /var/log/killercoda/background0_std(err|out).log

# variables
WAIT_SEC=5
BACKEND_NAMESPACE="juiceshop"
BACKEND_POD="juiceshop"
BACKEND_SVC="$BACKEND_POD"
BACKEND_SETUP_FINISH="/tmp/.backend_installed"
PORT_FORWARD_PID="/tmp/.backend-port-forward-pid"
OPERATOR_SETUP_FINISHED="/tmp/.operator_installed"
RC=99

# Part 1: setup backend web app
echo "$(date) : applying backend web app..."
kubectl apply -f ~/.scenario_staging/${BACKEND_POD}.yaml
echo "$(date) : waiting for ${BACKEND_NAMESPACE}/${BACKEND_POD} to be ready..."
kubectl wait pods ${BACKEND_POD} -n ${BACKEND_NAMESPACE} --for='condition=Ready' --timeout=300s
echo "$(date) : wait ${WAIT_SEC}s..."
sleep $WAIT_SEC
echo "$(date) : setting up ${BACKEND_NAMESPACE}/${BACKEND_POD} port forwarding..."
while [ $RC -gt 0 ]; do
  pkill -F $PORT_FORWARD_PID || true
  echo "$(date) : ...setting up port-forwarding and testing access..."
  nohup kubectl port-forward -n ${BACKEND_NAMESPACE} svc/${BACKEND_SVC} 8080:8080 --address 0.0.0.0 >/dev/null &
  echo $! > $PORT_FORWARD_PID
  sleep 3
  curl -svo /dev/null http://localhost:8080
  RC=$?
done
touch $BACKEND_SETUP_FINISH && echo "$(date) : wrote file $BACKEND_SETUP_FINISH to indicate backend setup completion to foreground process"
echo "$(date) : backend setup finished"
# Part 2: setup core waap operator
export CORE_WAAP_HELM_VERSION=1.1.1
export CONTAINER_REGISTRY=devuspregistry.azurecr.io
sleep $WAIT_SEC
echo "$(date) : login to helm registry..."
echo "RVkvOFNDMzdWWlo5VWsvSlZFcjRZK2pOSVAraGZiZ29pMmtaSE9DS3k1K0FDUkIrV015Yg==" | base64 -d | helm registry login ${CONTAINER_REGISTRY} --username killercoda --password-stdin
echo "$(date) : change to scenario_staging dir..."
cd ~/.scenario_staging/
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
echo "$(date) : signal foreground script completion..."
touch /tmp/.operator_installed
echo "$(date) : core waap operator setup finished"
