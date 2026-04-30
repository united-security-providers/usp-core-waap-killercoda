#!/bin/bash

# SPDX-FileCopyrightText: 2026 United Security Providers AG, Switzerland
#
# SPDX-License-Identifier: GPL-3.0-only

# workaround as killercoda seems to timeout on backupscripts after 10+ secs
bash ~/.scenario_staging/step3-autolearn-loop.sh &
exit 0
