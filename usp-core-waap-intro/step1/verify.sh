#!/bin/bash

kubectl logs juiceshop -n juiceshop |grep loginAdminChallenge
