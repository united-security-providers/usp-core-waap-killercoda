#!/bin/bash
FILE=~/.scenario_staging/intro-foreground.sh; while ! test -f ${FILE}; do clear; sleep 0.1; done; bash ${FILE}
