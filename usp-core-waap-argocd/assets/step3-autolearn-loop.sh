#!/bin/bash

# SPDX-FileCopyrightText: 2026 United Security Providers AG, Switzerland
#
# SPDX-License-Identifier: GPL-3.0-only

# Redirect stdout/stderr to log file
exec > /var/log/killercoda/background_step3_stdout.log
exec 2> /var/log/killercoda/background_step3_stderr.log

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
_AUTOLEARN_BRANCH="autolearn-tool"
_KILLERCODA_NODE_IP="172.30.2.2"
GOGS_API_PORT=30080
GOGS_API_PROTO=http
GOGS_API_SERVER="${_KILLERCODA_NODE_IP}"
JUICESHOP_NAMESPACE="juiceshop"
JUICESHOP_REPO_BASEDIR="${HOME}/repodata"
JUICESHOP_WAAP_CONFIGFILE="${JUICESHOP_NAMESPACE}/waap.yaml"
JUICESHOP_WAAP_LOGFILE="${JUICESHOP_NAMESPACE}/.waap.log"
WAIT_SECONDS=10

##################################################
# Main procedure
##################################################

log_info "initializing autolearn-branch and check for rule exceptions ..."

# test gogs API availability before proceeding
wait_for_url "${GOGS_API_PROTO}://${GOGS_API_SERVER}:${GOGS_API_PORT}" \
  || log_error "gogs API is not available at ${GOGS_API_PROTO}://${GOGS_API_SERVER}:${GOGS_API_PORT}"

cd "${JUICESHOP_REPO_BASEDIR}" || log_error "failed to change directory to repodata repository"

# check main and update
git checkout main || log_error "failed to checkout main branch in repodata repository"
git pull || log_error "failed to pull latest changes in repodata repository"
# create new branch for changes
git checkout -b "$_AUTOLEARN_BRANCH" \
  || git checkout "$_AUTOLEARN_BRANCH" \
  || log_error "failed to create/switch to new branch ${_AUTOLEARN_BRANCH} in repodata repository"
while true; do
  log_info "Aquiring Core WAAP logs and running auto-learn tool..."
  # get latest waap logs
  kubectl -n ${JUICESHOP_NAMESPACE} logs deploy/juiceshop-usp-core-waap > "${JUICESHOP_REPO_BASEDIR}/${JUICESHOP_WAAP_LOGFILE}" || log_error "failed to get latest waap logs from juice shop namespace in kubernetes cluster"
  # run auto-learning tool
  _AUTOLEARN_OUTPUT=$(
    java -jar ~/corewaap-autolearn-cli.jar \
      -i "${JUICESHOP_REPO_BASEDIR}/${JUICESHOP_WAAP_CONFIGFILE}" \
      -o "${JUICESHOP_REPO_BASEDIR}/${JUICESHOP_WAAP_CONFIGFILE}" \
      -l "${JUICESHOP_REPO_BASEDIR}/${JUICESHOP_WAAP_LOGFILE}" \
      crs \
      --reduceconfigured \
      --sortexceptions 2>&1
  )
  if [[ "$_AUTOLEARN_OUTPUT" == *" exceptions: 0/0"* ]]; then
    log_info "No new exceptions found by autolearn tool, resetting changes in git repository if any..."
    git checkout -- "${JUICESHOP_REPO_BASEDIR}/${JUICESHOP_WAAP_CONFIGFILE}" || log_error "failed to reset changes in repodata repository"
    log_info "No exceptions found, wating for ${WAIT_SECONDS} seconds before next check..."
    sleep $WAIT_SECONDS
  else
    log_info "Adding new exceptions to git repository"
    # add changes and commit
    git add "${JUICESHOP_REPO_BASEDIR}/${JUICESHOP_WAAP_CONFIGFILE}" || log_error "failed to add changes to git repository"
    git commit -m "exceptions by autolearn tool $(date +%Y-%m-%d\ %H:%M:%S)" || log_error "failed to commit changes to git repository"
    git push origin "$_AUTOLEARN_BRANCH" || log_error "failed to push changes to git repository"
    # create pull request (https://gogs.io/api-reference/introduction)
    # missing support from gogs https://github.com/gogs/gogs/issues/2253"
  fi
done
