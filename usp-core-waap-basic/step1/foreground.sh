#!/bin/bash

clear

echo -n "Installing scenario..."
while [ ! -f /tmp/.juiceshop-finished ]; do
    echo -n '.'
    sleep 1;
done;
echo " done"
echo "you should now be able to access the web app using the link on the left pane"

echo
