#!/bin/sh

FLAVOR="$1"

cd "tests/$FLAVOR" || exit

../../scripts/wait-for-app-of-apps.sh
