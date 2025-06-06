#!/bin/bash

# SPDX-FileCopyrightText: 2025 United Security Providers AG, Switzerland
#
# SPDX-License-Identifier: GPL-3.0-only

# as killercoda seems to flag a step-background script after 10+ secs
# trigger an external script
bash ~/.scenario_staging/wait-for-core-waap-instance.sh &
exit 0
