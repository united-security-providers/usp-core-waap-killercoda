#!/bin/bash

# SPDX-FileCopyrightText: 2025 United Security Providers AG, Switzerland
#
# SPDX-License-Identifier: GPL-3.0-only

FILE=~/.scenario_staging/step1-foreground.sh; while ! test -f ${FILE}; do clear; sleep 0.1; done; bash ${FILE}
