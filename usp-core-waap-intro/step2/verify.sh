#!/bin/bash

# SPDX-FileCopyrightText: 2025 United Security Providers AG, Switzerland
#
# SPDX-License-Identifier: GPL-3.0-only

kubectl wait pods --all -n usp-core-waap-operator --for='condition=Ready' --timeout=60s
