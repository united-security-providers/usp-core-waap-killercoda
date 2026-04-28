#!/bin/bash

# SPDX-FileCopyrightText: 2026 United Security Providers AG, Switzerland
#
# SPDX-License-Identifier: GPL-3.0-only

#
# intro background script log available at /var/log/killercoda/background0_std(err|out).log


##################################################
# Initialization
##################################################
echo "*** $(date) : initializing variables..."
ARGOCD_API_PORT=30081
ARGOCD_DEMO_APP_NAME="corewaap-juiceshop-demo"
ARGOCD_DEMO_APP_NAMESPACE="juiceshop"
ARGOCD_DEMO_APP_PATH="juiceshop"
ARGOCD_NAMESPACE="argocd"
ARGOCD_PROJECT="default"
ARGOCD_REPO_NAME="usp-helm-registry"
BACKEND_SETUP_FINISH="/tmp/.backend_installed"
COREWAAP_HELM_CHART="helm/usp/core/waap/usp-core-waap-operator"
COREWAAP_HELM_VERSION="2.0.0"
COREWAAP_OPERATOR_IMAGE_PATH="usp/core/waap/demo/usp-core-waap-operator"
COREWAAP_OPERATOR_NAMESPACE="usp-core-waap-operator"
COREWAAP_PROXY_IMAGE_PATH="usp/core/waap/demo/usp-core-waap-proxy-demo"
COREWAAP_REGISTRY_PASS="RVkvOFNDMzdWWlo5VWsvSlZFcjRZK2pOSVAraGZiZ29pMmtaSE9DS3k1K0FDUkIrV015Yg=="
COREWAAP_REGISTRY_SERVER="devuspregistry.azurecr.io"
COREWAAP_REGISTRY_USER="killercoda"
GOGS_API_PORT=30080
GOGS_API_URL="http://172.30.1.2:30080/api/v1"
GOGS_EMAIL="gituser@gogs.local"
GOGS_NAMESPACE="gogs"
GOGS_PASSWORD="gitpassword"
GOGS_REPO="testrepo"
GOGS_USER="gituser"
KILLERCODA_NODE_IP="172.30.1.2"

echo "*** $(date) : change to scenario_staging dir..."
cd ~/.scenario_staging/ || exit 1

##################################################
# Part 1: setup argocd backend application
##################################################
echo "*** $(date) : installing argocd..."

# install argocd stable into kubernets
kubectl create namespace ${ARGOCD_NAMESPACE} || exit 1
kubectl apply -n ${ARGOCD_NAMESPACE} --server-side --force-conflicts -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# install argocd cli
curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd || exit 1
rm argocd-linux-amd64

# wait for argocd k8s install to be ready
kubectl -n ${ARGOCD_NAMESPACE} wait --all --for=condition=Ready --timeout 300s pod

# argocd cli login
kubectl config set-context --current --namespace=${ARGOCD_NAMESPACE}
argocd login --core || exit 1

# make argocd UI accessible
# reconfiguring argocd to insecure mode is required to access http port (for killercoda for example)
kubectl patch configmap argocd-cmd-params-cm -n ${ARGOCD_NAMESPACE} \
  --type merge \
  -p '{"data":{"server.insecure":"true"}}'
kubectl rollout restart deployment argocd-server -n ${ARGOCD_NAMESPACE}

# wait for argocd k8s install to be ready
kubectl -n ${ARGOCD_NAMESPACE} wait --all --for=condition=Ready --timeout 300s pod

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

# add image pull secret to argocd namespace
kubectl apply -n ${ARGOCD_NAMESPACE} -f ./imagepullsecret.yaml

##################################################
# Part 2: setup gogs backend application
##################################################
echo "*** $(date) : installing gogs..."

# apply gogs manifests
kubectl create namespace ${GOGS_NAMESPACE} || exit 1
kubectl apply -n ${GOGS_NAMESPACE} -f ./gogs.yaml

# wait for gogs k8s install to be ready
kubectl wait pods -l app=gogs -n ${GOGS_NAMESPACE} --for='condition=Ready' --timeout=300s

# create initial gogs user and repo via gogs API
kubectl exec -n ${GOGS_NAMESPACE} deployment/gogs -- /app/gogs/gogs admin create-user --name ${GOGS_USER} --password ${GOGS_PASSWORD} --email ${GOGS_EMAIL}

##################################################
# Part 3: initialize gogs repository and webhook
##################################################
echo "*** $(date) : initializing gogs repository and configure webhook URL ..."

# get user access token
GOGS_TOKEN=$(curl -s -u "${GOGS_USER}:${GOGS_PASSWORD}" -X POST ${GOGS_API_URL}/users/${GOGS_USER}/tokens -H "Content-Type: application/json" -d "{\"name\":\"my_token\"}" | jq -r '.sha1')
test -n "$GOGS_TOKEN" && echo "*** $(date) : obtained gogs token for user ${GOGS_USER}" || echo "!!! $(date) : ERROR: failed to obtain gogs token for user ${GOGS_USER}"

# create repository
curl --fail -s -X POST ${GOGS_API_URL}/user/repos \
  -H "Authorization: token ${GOGS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{\"name\":\"${GOGS_REPO}\"}" \
  || echo "!!! $(date) : ERROR: failed to create gogs repository ${GOGS_REPO}"
sleep 2

# configure webhook for argocd
curl --fail -s -X POST ${GOGS_API_URL}/repos/${GOGS_USER}/${GOGS_REPO}/hooks \
  -H "Authorization: token ${GOGS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{\"type\":\"gogs\",\"config\":{\"url\":\"http://${KILLERCODA_NODE_IP}:${GOGS_API_PORT}/api/webhook\",\"content_type\":\"json\"},\"events\":[\"push\"]}" \
  || echo "!!! $(date) : ERROR: failed to create webhook for gogs repository ${GOGS_REPO}"

##################################################
# Part 4: create argocd corewaap operator application
##################################################
echo "*** $(date) : creating argocd application for usp core waap operator ..."

# prepare corewaap operator namespace and image pull secret for argocd
kubectl create namespace ${COREWAAP_OPERATOR_NAMESPACE} || exit 1
kubectl apply -n ${COREWAAP_OPERATOR_NAMESPACE} -f ./imagepullsecret.yaml

# add usp core waap helm repo
HELM_REPO_SECRET=$(echo -n "${COREWAAP_REGISTRY_PASS}" | base64 -d)
argocd repo add ${COREWAAP_REGISTRY_SERVER} \
  --project ${ARGOCD_PROJECT} \
  --username ${COREWAAP_REGISTRY_USER} \
  --password ${HELM_REPO_SECRET} \
  --project ${ARGOCD_PROJECT} \
  --name ${ARGOCD_REPO_NAME} \
  --type helm \
  --enable-oci
sleep 3

# add usp core waap operator application
argocd app create "${COREWAAP_OPERATOR_NAMESPACE}" \
  --project ${ARGOCD_PROJECT} \
  --repo ${COREWAAP_REGISTRY_SERVER} \
  --revision ${COREWAAP_HELM_VERSION} \
  --helm-chart ${COREWAAP_HELM_CHART} \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace ${COREWAAP_OPERATOR_NAMESPACE} \
  --sync-option CreateNamespace=true \
  --sync-policy automated \
  --parameter image.pullSecrets[0].name=devuspacr \
  --parameter operator.config.waapSpecDefaults.image="${COREWAAP_REGISTRY_SERVER}/${COREWAAP_PROXY_IMAGE_PATH}" \
  --parameter operator.imagePullSecretName=devuspacr \
  --parameter operator.image="${COREWAAP_REGISTRY_SERVER}/${COREWAAP_OPERATOR_IMAGE_PATH}"

##################################################
# Part 5: download autolearning cli
##################################################
echo "*** $(date) : installing java runtime environment..."
sudo apt install -y openjdk-17-jre-headless

# identify operator version and download corresponding autolearn cli
echo "*** $(date) : downloading autolearning cli ..."
COREWAAP_OPERATOR_VERSION=$(kubectl -n ${COREWAAP_OPERATOR_NAMESPACE} get pods -l app.kubernetes.io/name=core-waap-operator -o json | jq -r '.items[].metadata.labels["app.kubernetes.io/version"]')
COREWAAP_AUTOLEARN_CLI_FILENAME="corewaap-autolearn-cli.jar"
COREWAAP_AUTOLEARN_CLI_URL="https://docs.united-security-providers.ch/usp-core-waap/latest/files/waap-lib-autolearn-cli-${COREWAAP_OPERATOR_VERSION}.jar"
curl --fail -so "${COREWAAP_AUTOLEARN_CLI_FILENAME}" \
  "${COREWAAP_AUTOLEARN_CLI_URL}" \
  || echo "!!! $(date) : ERROR: failed to download autolearn-cli for version ${COREWAAP_OPERATOR_VERSION} from ${COREWAAP_AUTOLEARN_CLI_URL}"

##################################################
# Part 6: initialize git cli env and repository
##################################################
echo "*** $(date) : configuring local git cli and pushing initial repodata to gogs repository ..."

# configure local git
git config --global init.defaultBranch main
git config --global user.name "${GOGS_USER}"
git config --global user.email "${GOGS_EMAIL}"

# intialize repo and push to gogs
cd ~/repodata || exit 1
git init
git add .
git commit -m 'intitial repo commit'

git remote add origin http://${GOGS_USER}:${GOGS_PASSWORD}@${KILLERCODA_NODE_IP}:${GOGS_API_PORT}/${GOGS_USER}/${GOGS_REPO}.git
git push -u origin main || exit 1

##################################################
# Part 7: create juiceshop/corewaap app in argocd
##################################################
echo "*** $(date) : creating juiceshop/corewaap app in argocd ..."

# prepare corewaap operator namespace and image pull secret for argocd
kubectl create namespace ${ARGOCD_DEMO_APP_NAMESPACE} || exit 1
kubectl apply -n ${ARGOCD_DEMO_APP_NAMESPACE} -f ./imagepullsecret.yaml

# create argocd demo application
argocd app create "${ARGOCD_DEMO_APP_NAME}" \
  --project ${ARGOCD_PROJECT} \
  --path ${ARGOCD_DEMO_APP_PATH} \
  --repo http://${KILLERCODA_NODE_IP}:${GOGS_API_PORT}/${GOGS_USER}/${GOGS_REPO}.git \
  --dest-namespace ${ARGOCD_DEMO_APP_NAMESPACE} \
  --dest-server https://kubernetes.default.svc \
  --revision main \
  --sync-policy automated

##################################################
# Finalization: signal setup complete to foreground script
##################################################
echo "*** $(date) : removing local imagepullsecret.yaml..."
rm -f ~/.scenario_staging/imagepullsecret.yaml
touch $BACKEND_SETUP_FINISH && echo "*** $(date) : wrote file $BACKEND_SETUP_FINISH to indicate backend setup completion to foreground process"
echo "*** $(date) : backend setup finished"
