#!/bin/bash

# SPDX-FileCopyrightText: 2025 United Security Providers AG, Switzerland
#
# SPDX-License-Identifier: GPL-3.0-only

# Redirect stdout/stderr to log file
exec > /var/log/killercoda/background_step2_stdout.log
exec 2> /var/log/killercoda/background_step2_stderr.log

PORT_FORWARD_PID="/tmp/.backend-port-forward-pid"
if [ -e "$PORT_FORWARD_PID" ]; then
  echo "$(date) : terminating previous port-forwarding..."
  pkill -F $PORT_FORWARD_PID || echo "$(date) : WARNING! killing of previous port-forwarding indicated non-zero return-code"
else
  echo "$(date) : WARNING! skipping port forward terminating due to missing PID file $PORT_FORWARD_PID ..."
fi
