#!/bin/bash

# SPDX-FileCopyrightText: 2025 United Security Providers AG, Switzerland
#
# SPDX-License-Identifier: GPL-3.0-only

kubectl -n juiceshop logs pod/juiceshop | grep 'at /juice-shop/build/routes/userProfile.js'
