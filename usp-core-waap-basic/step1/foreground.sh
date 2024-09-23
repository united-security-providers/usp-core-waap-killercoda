#!/bin/bash

echo "waiting for juiceshop deployment being ready..."
while [ ! -f /tmp/.juiceshop-port-forward-pid ]; do
  clear
  sleep 5
  echo "...please wait for deployment to be ready and accessible via browser..."
done
clear
