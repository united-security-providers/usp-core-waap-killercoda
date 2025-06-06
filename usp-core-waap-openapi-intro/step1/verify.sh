#!/bin/bash

# SPDX-FileCopyrightText: 2025 United Security Providers AG, Switzerland
#
# SPDX-License-Identifier: GPL-3.0-only

kubectl -n petstore exec pod/petstore -- /bin/bash -c "grep -E 'GET /api/pet/cat1 .*' /var/log/*-requests.log"
