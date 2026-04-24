#!/bin/bash

# SPDX-FileCopyrightText: 2025 United Security Providers AG, Switzerland
#
# SPDX-License-Identifier: GPL-3.0-only

#
# intro background script log available at /var/log/killercoda/background0_std(err|out).log


##################################################
# Initialization
##################################################
# variables
ARGOCD_NAMESPACE="argocd"
GOGS_NAMESPACE="gogs"
GOGS_USER="gituser"
GOGS_PASSWORD="gitpassword"
GOGS_EMAIL="gituser@gogs.local"
GOGS_REPO="testrepo"
GOGS_API_URL="http://172.30.1.2:30080/api/v1"
BACKEND_SETUP_FINISH="/tmp/.backend_installed"

echo "$(date) : change to scenario_staging dir..."
cd ~/.scenario_staging/ || exit 1

##################################################
# Part 1: setup argocd backend application
##################################################
echo "$(date) : installing argocd..."
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
kubectl patch svc argocd-server -n ${ARGOCD_NAMESPACE} -p '{"spec":{"type":"NodePort","ports":[{"port":80, "nodePort":30081}]}}'

##################################################
# Part 2: setup gogs backend application
##################################################

echo "$(date) : installing gogs..."
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

# get user access token
GOGS_TOKEN=$(curl -s -u "${GOGS_USER}:${GOGS_PASSWORD}" -X POST ${GOGS_API_URL}/users/${GOGS_USER}/tokens -H "Content-Type: application/json" -d "{\"name\":\"my_token\"}" | jq -r '.sha1')

# create repository
curl -s -X POST ${GOGS_API_URL}/user/repos \
  -H "Authorization: token ${GOGS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{\"name\":\"${GOGS_REPO}\"}"

# configure webhook for argocd
curl -s -X POST ${GOGS_API_URL}/repos/${GOGS_USER}/${GOGS_REPO}/hooks \
  -H "Authorization: token ${GOGS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{\"type\":\"gogs\",\"config\":{\"url\":\"http://172.30.1.2:30081/api/webhook\",\"content_type\":\"json\"},\"events\":[\"push\"]}"

##################################################
# Finalization: signal setup complete to foreground script
##################################################
touch $BACKEND_SETUP_FINISH && echo "$(date) : wrote file $BACKEND_SETUP_FINISH to indicate backend setup completion to foreground process"
echo "$(date) : backend setup finished"
