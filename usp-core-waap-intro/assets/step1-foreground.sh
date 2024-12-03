#!/bin/bash

rm $0

clear

echo -n "Installing scenario..."
while [ ! -f /tmp/.backend_installed ]; do
  echo -n '.'
  sleep 1;
done;
echo " done"
echo
echo "*** Scenario ready ***"
