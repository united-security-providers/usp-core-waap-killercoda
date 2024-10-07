#!/bin/bash

echo "waiting for juiceshop deployment being ready..."
while [ ! -f /tmp/.juiceshop-finished ]; do
  clear
  echo "...please wait for deployment to be ready and accessible via browser..."
  sleep 3
done
RC=99
PORT_FORWARD_PID="/tmp/.juiceshop-port-forward-pid"
while [ $RC -gt 0 ]; do
  clear
  pkill -F $PORT_FORWARD_PID || true
  echo "...setting up port-forwarding and testing access..."
  nohup kubectl port-forward -n juiceshop svc/juiceshop 80:8000 --address 0.0.0.0 >/dev/null &
  echo $! > $PORT_FORWARD_PID
  sleep 3
  curl -svo /dev/null http://localhost:80
  RC=$?
done
clear
echo "...deployment ready! you should now be able to access the web app using the link on the left pane"
