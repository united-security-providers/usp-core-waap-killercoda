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
ARGOCD_API_PORT=30081
ARGOCD_CLI_DOWNLOAD_URL="https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64"
ARGOCD_DEMO_APP_NAME="corewaap-juiceshop-demo"
ARGOCD_DEMO_APP_NAMESPACE="juiceshop"
ARGOCD_DEMO_APP_PATH="juiceshop"
ARGOCD_NAMESPACE="argocd"
ARGOCD_PROJECT="default"
ARGOCD_REPO_NAME="usp-helm-registry"
BACKEND_SETUP_ARGOCD="/tmp/.backend_argocd_installed"
BACKEND_SETUP_DEMO_APP="/tmp/.backend_demo_app_installed"
BACKEND_SETUP_FINISH="/tmp/.backend_installed"
BACKEND_SETUP_GOGS="/tmp/.backend_gogs_installed"
BACKEND_SETUP_WAAP_OPERATOR="/tmp/.backend_corewaap_operator_installed"
COREWAAP_HELM_CHART="helm/usp/core/waap/usp-core-waap-operator"
COREWAAP_HELM_VERSION="2.0.0"
COREWAAP_OPERATOR_IMAGE_PATH="usp/core/waap/demo/usp-core-waap-operator"
COREWAAP_OPERATOR_NAMESPACE="usp-core-waap-operator"
COREWAAP_PROXY_IMAGE_PATH="usp/core/waap/demo/usp-core-waap-proxy-demo"
COREWAAP_REGISTRY_PASS="RVkvOFNDMzdWWlo5VWsvSlZFcjRZK2pOSVAraGZiZ29pMmtaSE9DS3k1K0FDUkIrV015Yg=="
COREWAAP_REGISTRY_SERVER="devuspregistry.azurecr.io"
COREWAAP_REGISTRY_USER="killercoda"
GOGS_API_PORT=30080
GOGS_API_PROTO=http
GOGS_API_SERVER="${_KILLERCODA_NODE_IP}"
GOGS_API_URL="${GOGS_API_PROTO}://${GOGS_API_SERVER}:${GOGS_API_PORT}/api/v1"
GOGS_EMAIL="gituser@gogs.local"
GOGS_NAMESPACE="gogs"
GOGS_PASSWORD="gitpassword"
GOGS_REPO="testrepo"
GOGS_USER="gituser"

log_info "change to scenario_staging dir..."
cd ~/.scenario_staging/ || exit 1

##################################################
# Part 1: setup argocd backend application
##################################################
log_info "installing argocd..."

# install argocd stable into kubernets
kubectl create namespace ${ARGOCD_NAMESPACE} || log_error "failed to create namespace ${ARGOCD_NAMESPACE}, it might already exist, proceeding with installation"
kubectl apply -n ${ARGOCD_NAMESPACE} --server-side --force-conflicts -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# add image pull secret to argocd namespace
kubectl apply -n ${ARGOCD_NAMESPACE} -f ./imagepullsecret.yaml || log_error "failed to apply image pull secret to argocd namespace ${ARGOCD_NAMESPACE}"

# install argocd cli
curl --fail -sSL -o argocd-linux-amd64 ${ARGOCD_CLI_DOWNLOAD_URL} \
  || log_error "failed to download argocd cli from ${ARGOCD_CLI_DOWNLOAD_URL}"
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd || log_error "failed to install argocd cli to /usr/local/bin/argocd"
rm argocd-linux-amd64

# wait for argocd k8s install to be ready
kubectl -n ${ARGOCD_NAMESPACE} wait --all --for=condition=Ready --timeout 300s pod \
  || log_error "argocd k8s installation is not ready after waiting for 300s"

# argocd cli login
kubectl config set-context --current --namespace=${ARGOCD_NAMESPACE}
argocd login --core || log_error "failed to login to argocd CLI"

# make argocd UI accessible
# reconfiguring argocd to insecure mode is required to access http port (for killercoda for example)
kubectl patch configmap argocd-cmd-params-cm -n ${ARGOCD_NAMESPACE} \
  --type merge \
  -p '{"data":{"server.insecure":"true"}}'
kubectl rollout restart deployment argocd-server -n ${ARGOCD_NAMESPACE}

# wait for argocd k8s install to be ready
kubectl -n ${ARGOCD_NAMESPACE} wait --all --for=condition=Ready --timeout 300s pod \
  || log_error "argocd k8s installation is not ready after waiting for 300s after patching configmap"

# patch svc to be of type NodePort and access via port 30081
cat << EOF > argocd-server-svc-patch.yaml
spec:
  type: NodePort
  ports:
    - port: 80
      nodePort: ${ARGOCD_API_PORT}
EOF
kubectl patch svc argocd-server \
  --namespace ${ARGOCD_NAMESPACE} \
  --patch-file argocd-server-svc-patch.yaml

# wait for argocd server to be ready after patching svc
wait_for_url "http://${_KILLERCODA_NODE_IP}:${ARGOCD_API_PORT}" \
  || log_error "argocd API is not available at http://${_KILLERCODA_NODE_IP}:${ARGOCD_API_PORT}/api/v1"

touch ${BACKEND_SETUP_ARGOCD} && log_info "wrote file $BACKEND_SETUP_ARGOCD to indicate argocd installation completion to foreground process"

##################################################
# Part 2: setup gogs backend application
##################################################
log_info "installing gogs..."

# apply gogs manifests
kubectl create namespace ${GOGS_NAMESPACE} || log_error "failed to create namespace ${GOGS_NAMESPACE}"
kubectl apply -n ${GOGS_NAMESPACE} -f ./gogs.yaml || log_error "failed to apply gogs manifests to namespace ${GOGS_NAMESPACE}"

# wait for gogs k8s install to be ready
kubectl wait pods -l app=gogs -n ${GOGS_NAMESPACE} --for='condition=Ready' --timeout=300s \
  || log_error "gogs k8s installation is not ready after waiting for 300s"

# create initial gogs user and repo via gogs API
kubectl exec -n ${GOGS_NAMESPACE} deployment/gogs -- /app/gogs/gogs admin create-user --name ${GOGS_USER} --password ${GOGS_PASSWORD} --email ${GOGS_EMAIL} \
  || log_error "failed to create initial gogs user ${GOGS_USER} via gogs admin CLI"


##################################################
# Part 3: initialize gogs repository and webhook
##################################################
log_info "initializing gogs repository and configure webhook URL ..."

# test gogs API availability before proceeding
wait_for_url "${GOGS_API_PROTO}://${GOGS_API_SERVER}:${GOGS_API_PORT}" \
  || log_error "gogs API is not available at ${GOGS_API_PROTO}://${GOGS_API_SERVER}:${GOGS_API_PORT}"

# get user access token
GOGS_TOKEN=$(curl --fail -s -u "${GOGS_USER}:${GOGS_PASSWORD}" -X POST ${GOGS_API_URL}/users/${GOGS_USER}/tokens -H "Content-Type: application/json" -d "{\"name\":\"setup_token\"}" | jq -r '.sha1')
test -n "$GOGS_TOKEN" && log_info "obtained gogs token for user ${GOGS_USER}" || log_error "failed to obtain gogs token for user ${GOGS_USER}"

# create repository
curl --fail -v -X POST ${GOGS_API_URL}/user/repos \
  -H "Authorization: token ${GOGS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{\"name\":\"${GOGS_REPO}\"}" \
  || log_error "failed to create gogs repository ${GOGS_REPO}"

# configure webhook for argocd
curl --fail -v -X POST ${GOGS_API_URL}/repos/${GOGS_USER}/${GOGS_REPO}/hooks \
  -H "Authorization: token ${GOGS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{\"type\":\"gogs\",\"active\":true,\"config\":{\"url\":\"http://${_KILLERCODA_NODE_IP}:${ARGOCD_API_PORT}/api/webhook\",\"content_type\":\"json\"},\"events\":[\"push\"]}" \
  || log_error "failed to create webhook for gogs repository ${GOGS_REPO}"

touch ${BACKEND_SETUP_GOGS} && log_info "wrote file $BACKEND_SETUP_GOGS to indicate gogs installation completion to foreground process"

##################################################
# Part 4: create argocd corewaap operator application
##################################################
log_info "creating argocd application for usp core waap operator ..."

# prepare corewaap operator namespace and image pull secret for argocd
kubectl create namespace ${COREWAAP_OPERATOR_NAMESPACE} || log_error "failed to create namespace ${COREWAAP_OPERATOR_NAMESPACE}"
kubectl apply -n ${COREWAAP_OPERATOR_NAMESPACE} -f ./imagepullsecret.yaml || log_error "failed to apply image pull secret to namespace ${COREWAAP_OPERATOR_NAMESPACE}"

# add usp core waap helm repo
HELM_REPO_SECRET=$(echo -n "${COREWAAP_REGISTRY_PASS}" | base64 -d)
argocd repo add ${COREWAAP_REGISTRY_SERVER} \
  --project ${ARGOCD_PROJECT} \
  --username ${COREWAAP_REGISTRY_USER} \
  --password ${HELM_REPO_SECRET} \
  --project ${ARGOCD_PROJECT} \
  --name ${ARGOCD_REPO_NAME} \
  --type helm \
  --enable-oci \
  || log_error "failed to add argocd helm repository ${COREWAAP_REGISTRY_SERVER}"

# add usp core waap operator application
cat << EOF > corewaap-operator-argocd-values.yaml
image:
  pullSecrets:
    - name: devuspacr
operator:
  imagePullSecretName: devuspacr
  serviceAccount: usp-core-waap-operator
  resources:
    requests:
      cpu: 100m
      memory: 64Mi
  config:
    waapSpecDefaults:
      resources:
        requests:
          cpu: 100m
          memory: 256Mi
EOF
argocd app create "${COREWAAP_OPERATOR_NAMESPACE}" \
  --project ${ARGOCD_PROJECT} \
  --repo ${COREWAAP_REGISTRY_SERVER} \
  --revision ${COREWAAP_HELM_VERSION} \
  --helm-chart ${COREWAAP_HELM_CHART} \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace ${COREWAAP_OPERATOR_NAMESPACE} \
  --parameter operator.config.waapSpecDefaults.image="${COREWAAP_REGISTRY_SERVER}/${COREWAAP_PROXY_IMAGE_PATH}" \
  --parameter operator.image="${COREWAAP_REGISTRY_SERVER}/${COREWAAP_OPERATOR_IMAGE_PATH}" \
  --values-literal-file corewaap-operator-argocd-values.yaml \
  --sync-option CreateNamespace=true \
  --sync-policy automated \
  || log_error "failed to create argocd application ${COREWAAP_OPERATOR_NAMESPACE} for usp core waap operator helm chart ${COREWAAP_HELM_CHART}"

touch ${BACKEND_SETUP_WAAP_OPERATOR} && log_info "wrote file $BACKEND_SETUP_WAAP_OPERATOR to indicate corewaap operator argocd application creation completion to foreground process"

##################################################
# Part 5: download autolearning cli
##################################################
log_info "installing java runtime environment..."
sudo apt install -y openjdk-17-jre-headless \
  || log_error "failed to install java runtime environment"

# wait for corewaap operator to be ready before downloading autolearn cli, as the cli version needs to match the operator version
log_info "waiting for corewaap operator to be ready before downloading autolearn cli ..."
kubectl -n ${COREWAAP_OPERATOR_NAMESPACE} wait --for=condition=available deployment/core-waap-operator --timeout=300s \
  || log_error "waiting for corewaap operator deployment timed out, cannot proceed with autolearn cli download"

# identify operator version and download corresponding autolearn cli
log_info "downloading autolearning cli ..."
COREWAAP_OPERATOR_VERSION=$(kubectl -n ${COREWAAP_OPERATOR_NAMESPACE} get pods -l app.kubernetes.io/name=core-waap-operator -o json | jq -r '.items[].metadata.labels["app.kubernetes.io/version"]')
COREWAAP_AUTOLEARN_CLI_FILENAME="corewaap-autolearn-cli.jar"
COREWAAP_AUTOLEARN_CLI_URL="https://docs.united-security-providers.ch/usp-core-waap/latest/files/waap-lib-autolearn-cli-${COREWAAP_OPERATOR_VERSION}.jar"
curl --fail -so "${HOME}/${COREWAAP_AUTOLEARN_CLI_FILENAME}" \
  "${COREWAAP_AUTOLEARN_CLI_URL}" \
  || log_error "failed to download autolearn-cli for version ${COREWAAP_OPERATOR_VERSION} from ${COREWAAP_AUTOLEARN_CLI_URL}"

##################################################
# Part 6: initialize git cli env and repository
##################################################
log_info "configuring local git cli and pushing initial repodata to gogs repository ..."

# configure local git
git config --global init.defaultBranch main
git config --global user.name "${GOGS_USER}"
git config --global user.email "${GOGS_EMAIL}"

# intialize repo and push to gogs
cd ~/repodata || log_error "failed to change directory to ~/repodata for git repository initialization and push to gogs"
echo "*.log" > .gitignore || log_error "failed to create .gitignore file in ~/repodata for git repository initialization"
git init || log_error "failed to initialize git repository in ~/repodata"
git add . || log_error "failed to add repodata files to git repository in ~/repodata"
git commit -m 'intitial repo commit' || log_error "failed to commit repodata files to git repository in ~/repodata"

git remote add origin http://${GOGS_USER}:${GOGS_PASSWORD}@${_KILLERCODA_NODE_IP}:${GOGS_API_PORT}/${GOGS_USER}/${GOGS_REPO}.git \
  || log_error "failed to add gogs repository as git remote origin"
git push -u origin main \
  || log_error "failed to push initial repodata to gogs repository"

cd - || log_error "failed to change back to previous directory after pushing repodata to gogs repository"

##################################################
# Part 7: create juiceshop/corewaap app in argocd
##################################################
log_info "creating juiceshop/corewaap app in argocd ..."

# prepare corewaap operator namespace and image pull secret for argocd
kubectl create namespace ${ARGOCD_DEMO_APP_NAMESPACE} || log_error "failed to create namespace ${ARGOCD_DEMO_APP_NAMESPACE}"
kubectl apply -n ${ARGOCD_DEMO_APP_NAMESPACE} -f ./imagepullsecret.yaml || log_error "failed to apply image pull secret to namespace ${ARGOCD_DEMO_APP_NAMESPACE}"

# create argocd demo application
argocd app create "${ARGOCD_DEMO_APP_NAME}" \
  --project ${ARGOCD_PROJECT} \
  --path ${ARGOCD_DEMO_APP_PATH} \
  --repo http://${_KILLERCODA_NODE_IP}:${GOGS_API_PORT}/${GOGS_USER}/${GOGS_REPO}.git \
  --dest-namespace ${ARGOCD_DEMO_APP_NAMESPACE} \
  --dest-server https://kubernetes.default.svc \
  --revision main \
  --sync-policy automated \
  || log_error "failed to create argocd application ${ARGOCD_DEMO_APP_NAME} for demo app in path ${ARGOCD_DEMO_APP_PATH} of repository"

touch ${BACKEND_SETUP_DEMO_APP} && log_info "wrote file $BACKEND_SETUP_DEMO_APP to indicate demo app argocd application creation completion to foreground process"

##################################################
# Finalization: signal setup complete to foreground script
##################################################
log_info "removing local imagepullsecret.yaml..."
rm -f ~/.scenario_staging/imagepullsecret.yaml || log_error "failed to remove local imagepullsecret.yaml"
touch $BACKEND_SETUP_FINISH && log_info "wrote file $BACKEND_SETUP_FINISH to indicate backend setup completion to foreground process"
log_info "backend setup finished"
