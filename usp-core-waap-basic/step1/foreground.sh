#!/bin/bash

echo "waiting for juiceshop deployment being ready..."
while [ ! -f /tmp/.juiceshop-port-forward-pid ]; do
  clear
  echo "...please wait for deployment to be ready and accessible via browser..."
  sleep 5
done
clear
echo "...deployment ready you should now be able to access the web app using the link on the left pane"
