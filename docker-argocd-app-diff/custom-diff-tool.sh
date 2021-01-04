#!/bin/bash

# Compute and format diff
diff=$(mktemp)
diff -u $* | tail -n +4 > $diff
ret=${PIPESTATUS[0]}

if [ $ret -eq 1 ]; then
  echo '```diff'
  cat $diff
  echo '```'
else
  echo "*No differences*" > /dev/null
fi

exit $ret
