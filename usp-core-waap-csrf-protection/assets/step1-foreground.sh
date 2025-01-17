#!/bin/bash

rm $0

clear

echo -n "Installing attacker website..."
while [ ! -f /tmp/.attacker_installed ]; do
  echo -n '.'
  sleep 1;
done;
echo " done"
echo
echo "*** Scenario ready ***"