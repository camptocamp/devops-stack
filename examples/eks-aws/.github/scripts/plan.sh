#!/bin/sh

set -e

wget -O- "https://raw.githubusercontent.com/camptocamp/camptocamp-devops-stack/v$CAMPTOCAMP_DEVOPS_STACK_VERSION/scripts/plan.sh" | sh
