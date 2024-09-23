#!/bin/bash

# Redirect stdout/stderr to log file
exec > /var/log/killercoda/background_step3_stdout.log
exec 2> /var/log/killercoda/background_step3_stderr.log

# waiting for pod conditions only works once namespace/pod workload exists otherwise kubectl wait exits indication no resource found
echo "$(date) : waiting for corewaap instance to be configured..."
while true; do
  COREWAAPRESOURCES=$(grep juiceshop-usp-core-waap /var/log/containers/core-waap-operator-*.log | wc -l)
  if [[ ! "$COREWAAPRESOURCES" =~ ^[0-9]+$ ]]; then
      echo "$(date) : WARNING! failed to get list of corewaapservices (received value: $COREWAAPRESOURCES)"
  elif (( COREWAAPRESOURCES < 1 )); then
      echo "$(date) : ... corewaapservices.waap.core.u-s-p.ch resource found yet in namespace juiceshop"
      sleep 5
  else
      break
  fi
done

echo "$(date) : waiting for corewaap instance to be ready..."
kubectl wait pods -l app.kubernetes.io/name=usp-core-waap -n juiceshop --for='condition=Ready' --timeout=3m

# re-create the port forwarding via core-waap instance (once corewaap resource was configured by user)
echo "$(date) : re-creating portforwarding via corewaap..."
nohup kubectl -n juiceshop port-forward svc/juiceshop-usp-core-waap 8080:8080 --address 0.0.0.0 >/dev/null &

echo "$(date) : background script finished (last seen RC=$?)"
