#!/bin/bash

# SPDX-FileCopyrightText: 2025 United Security Providers AG, Switzerland
#
# SPDX-License-Identifier: GPL-3.0-only

sleep 5
grep APPLICATION-ATTACK-SQLI /var/log/containers/juiceshop-usp-core-waap-*.log
