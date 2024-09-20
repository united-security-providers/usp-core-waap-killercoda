#!/bin/bash

kubectl wait pods juiceshop --for='condition=Ready' --timeout=10
