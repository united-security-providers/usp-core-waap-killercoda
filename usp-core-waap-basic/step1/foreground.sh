#!/bin/bash

echo "waiting for juiceshop deployment being ready..."
while [ ! -f /tmp/.juiceshop-port-forward-pid ]; do
  clear
  echo "...please wait for deployment to be ready and accessible via browser..."
  sleep 5
done
sleep 3
nohup kubectl port-forward -n juiceshop svc/juiceshop 80:8000 --address 0.0.0.0 >/dev/null &
echo $! > /tmp/.juiceshop-port-forward-pid
clear
echo "...deployment ready you should now be able to access the web app using the link on the left pane"
