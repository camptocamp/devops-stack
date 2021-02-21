#!/bin/sh

set -e

python3 -c "import urllib.request; print(urllib.request.urlopen('https://raw.githubusercontent.com/camptocamp/camptocamp-devops-stack/v$CAMPTOCAMP_DEVOPS_STACK_VERSION/scripts/wait-for-app-of-apps.sh').read().decode())" | bash
