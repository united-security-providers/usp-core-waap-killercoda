#!/bin/bash

# SPDX-FileCopyrightText: 2026 United Security Providers AG, Switzerland
#
# SPDX-License-Identifier: GPL-3.0-only

PL_EXPECTED="3"
PL_ACTUAL=$(kubectl -n juiceshop get corewaapservices.waap.core.u-s-p.ch/juiceshop-usp-core-waap -o json | jq -r '.spec.coraza.crs.paranoiaLevel')

test "$PL_ACTUAL" = "$PL_EXPECTED"
