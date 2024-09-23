#!/bin/bash

kubectl wait pods --all -n usp-core-waap-operator --for='condition=Ready' --timeout=60s
