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
BACKEND_NAMESPACE="lldap"
BACKEND_POD="lldap"
BACKEND_PORT="17170"
BACKEND_SETUP_FINISH="/tmp/.backend_installed"
OPERATOR_SETUP_FINISHED="/tmp/.operator_installed"

# exports
export CORE_WAAP_HELM_VERSION="2.1.2"
export CORE_WAAP_AUTOLEARN_CLI_VERSION="2.1.0"
export CONTAINER_REGISTRY="devuspregistry.azurecr.io"
export CONTAINER_BASE_PATH="usp/core/waap/demo"

##################################################
# Part 1: setup lldap backend (https://github.com/lldap/lldap / https://artifacthub.io/packages/helm/alexmorbo-lldap/lldap)
##################################################
log_info "installing lldap backend app..."
helm upgrade --install \
  --create-namespace \
  -n ${BACKEND_NAMESPACE} \
  ${BACKEND_POD} \
  oci://ghcr.io/alexmorbo/helm-charts/lldap \
  --set 'secret.lldapUserPass=insecure' || exit 1
log_info "waiting for ${BACKEND_NAMESPACE}/${BACKEND_POD} to be ready..."
kubectl wait pods -l app.kubernetes.io/name=lldap -n ${BACKEND_NAMESPACE} --for='condition=Ready' --timeout=300s \
  || log_error "lldap pod in namespace ${BACKEND_NAMESPACE} is not ready after waiting for 300s"

log_info "creating node-port svc for lldap backend..."
cat << EOF | kubectl apply -f -
kind: Service
apiVersion: v1
metadata:
  name: ${BACKEND_POD}-nodeport
  namespace: ${BACKEND_NAMESPACE}
spec:
  type: NodePort
  selector:
    app.kubernetes.io/name: lldap
  ports:
  - name: http
    port: ${BACKEND_PORT}
    targetPort: ${BACKEND_PORT}
    nodePort: 30080
EOF
wait_for_url "http://${_KILLERCODA_NODE_IP}:30080" || log_error "backend web app is not accessible after waiting for 30 attempts"
log_info "backend web app is accessible"

log_info "query JWT authentication token..."
LLDAP_TOKEN=$(curl -s -X POST -H 'Content-Type: application/json' http://${_KILLERCODA_NODE_IP}:30080/auth/simple/login -d '{"username":"admin", "password":"insecure"}' | jq -r '.token')
if [ -z "$LLDAP_TOKEN" ] || [ "$LLDAP_TOKEN" == "null" ]; then
  log_error "LLDAP backend setup failed - please restart the scenario (if consistent report this error on scenario overview page)"
  exit 1
else
  echo "export LLDAP_TOKEN=$LLDAP_TOKEN" > ~/.ldap_token || exit 1
fi
touch $BACKEND_SETUP_FINISH && log_info "wrote file $BACKEND_SETUP_FINISH to indicate backend setup completion to foreground process"
log_info "backend setup finished"

##################################################
# Part 2: setup core waap operator
##################################################
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
cp ./${BACKEND_POD}-schema.graphql ~
log_info "core waap operator setup finished"

##################################################
# Part 3: install java and download Auto-Learning Tool
##################################################
log_info "installing java runtime environment..."
sudo apt install -y openjdk-25-jre-headless || log_error "failed to install java runtime environment"

# java wrapper hiding java 25 sun.misc.Unsafe warnings (caused by protobuf lib within autolearn cli)
log_info "installing java wrapper ..."
printf '#!/bin/sh\nexec /usr/bin/java --sun-misc-unsafe-memory-access=allow "$@"\n' \
  | sudo tee /usr/local/bin/java > /dev/null \
  || log_error "failed to install java wrapper"
sudo chmod +x /usr/local/bin/java || log_error "failed to make java wrapper executable"

# download autolearn cli (pinned, as only specific cli versions are published)
CORE_WAAP_AUTOLEARN_CLI_URL="https://docs.united-security-providers.ch/usp-core-waap/2.1.x/files/waap-lib-autolearn-cli-${CORE_WAAP_AUTOLEARN_CLI_VERSION}.jar"
log_info "downloading auto-learning cli tool version ${CORE_WAAP_AUTOLEARN_CLI_VERSION}..."
curl --fail -so ~/waap-lib-autolearn-cli.jar "${CORE_WAAP_AUTOLEARN_CLI_URL}" \
  || log_error "failed to download autolearn-cli for version ${CORE_WAAP_AUTOLEARN_CLI_VERSION} from ${CORE_WAAP_AUTOLEARN_CLI_URL}"
test -s ~/waap-lib-autolearn-cli.jar || exit 1
touch $OPERATOR_SETUP_FINISHED && log_info "wrote file $OPERATOR_SETUP_FINISHED to indicate operator installation setup completion to foreground process"
