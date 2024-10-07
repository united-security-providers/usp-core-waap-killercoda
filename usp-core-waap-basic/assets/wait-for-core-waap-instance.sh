#!/bin/bash

# Redirect stdout/stderr to log file
exec > /var/log/killercoda/background_step3_stdout.log
exec 2> /var/log/killercoda/background_step3_stderr.log

echo "$(date) : waiting for corewaap instance to be ready..."
RC=99
while [ $RC -gt 0 ]; do
  sleep 2
  kubectl wait pods -l app.kubernetes.io/name=usp-core-waap -n juiceshop --for='condition=Ready' --timeout=10s
  RC=$?
done
echo "$(date) : corewaap instance found in condition ready"

# re-create the port forwarding via core-waap instance (once corewaap resource was configured by user)
echo "$(date) : re-creating portforwarding via corewaap..."
RC=99
PORT_FORWARD_PID="/tmp/.core-waap-port-forward-pid"
while [ $RC -gt 0 ]; do
  clear
  pkill -F $PORT_FORWARD_PID || true
  echo "$(date) : ...setting up port-forwarding and testing access..."
  nohup kubectl -n juiceshop port-forward svc/juiceshop-usp-core-waap 8080:8080 --address 0.0.0.0 >/dev/null &
  echo $! > $PORT_FORWARD_PID
  sleep 3
  curl -svo /dev/null http://localhost:80
  RC=$?
done


echo "$(date) : background script finished (last seen RC=$?)"