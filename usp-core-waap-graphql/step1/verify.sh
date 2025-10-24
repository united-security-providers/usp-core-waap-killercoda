#!/bin/bash

# SPDX-FileCopyrightText: 2025 United Security Providers AG, Switzerland
#
# SPDX-License-Identifier: GPL-3.0-only

test -e /tmp/.backend_installed && curl -v 'http://localhost:8080/api/graphql' \
   -H 'Content-Type: application/json' \
   --silent \
   --cookie "token=$LLDAP_TOKEN" \
   --data '{"query": "query { groups { displayName } }"}' | jq
