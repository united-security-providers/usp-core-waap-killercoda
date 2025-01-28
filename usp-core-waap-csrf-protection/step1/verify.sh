#!/bin/bash

kubectl -n juiceshop logs pod/juiceshop | grep 'at /juice-shop/build/routes/userProfile.js'
