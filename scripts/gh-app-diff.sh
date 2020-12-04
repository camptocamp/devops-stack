#!/bin/sh

FLAVOR="$1"

cd "tests/$FLAVOR" || exit

../../scripts/app-diff.sh
