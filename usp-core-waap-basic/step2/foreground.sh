#!/bin/bash

clear
PORT_FORWARD_PID="/tmp/.juiceshop-port-forward-pid"
if [ -e "$PORT_FORWARD_PID" ]; then
  echo "$(date) : terminating previous port-forwarding..."
  pkill -F $PORT_FORWARD_PID || echo "$(date) : WARNING! killing of previous port-forwarding indicated non-zero return-code"
else
  echo "$(date) : WARNING! skipping port forward terminating due to missing PID file $PORT_FORWARD_PID ..."
fi

clear
echo "waiting for USP Core Waap operator installation being ready..."
while [ ! -f /tmp/.operator_installed ]; do sleep 1; done
kubectl wait pods --all -n usp-core-waap-operator --for='condition=Ready' --timeout=60s || echo "ERROR: core waap operator installation did not succeed!"
clear
