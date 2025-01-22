#!/bin/bash

rm $0

clear

echo -n "Installing USP Core WAAP Operator..."
while [ ! -f /tmp/.operator_installed ]; do
  echo -n '.'
  sleep 1;
done;
echo " done"
echo
echo "*** Scenario ready ***"
