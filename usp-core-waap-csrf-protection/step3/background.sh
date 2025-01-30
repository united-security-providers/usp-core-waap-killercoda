#!/bin/bash

# Redirect stdout/stderr to log file
exec > /var/log/killercoda/background_step3_stdout.log
exec 2> /var/log/killercoda/background_step3_stderr.log

# update attacker form with core-waap juiceshop URL
ATTACKER_POD="attacker-nginx"
kubectl apply -f /tmp/${ATTACKER_POD}-2.yaml

# kill initial port-forward
PORT_FORWARD_PID="/tmp/.backend-port-forward-pid"
if [ -e "$PORT_FORWARD_PID" ]; then
  echo "$(date) : terminating previous port-forwarding..."
  pkill -F $PORT_FORWARD_PID || echo "$(date) : WARNING! killing of previous port-forwarding indicated non-zero return-code"
else
  echo "$(date) : WARNING! skipping port forward terminating due to missing PID file $PORT_FORWARD_PID ..."
fi

# as killercoda seems to flag a step-background script after 10+ secs
# trigger an external script
bash ~/.scenario_staging/wait-for-core-waap-instance.sh &
exit 0
