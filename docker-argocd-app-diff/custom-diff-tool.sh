#!/bin/bash

kind=$(yq r $2 kind)
apiVersion=$(yq r $2 apiVersion)
name=$(yq r $2 metadata.name)
namespace=$(yq r $2 metadata.namespace)
parent_app=$(yq r $2 'metadata.labels."app.kubernetes.io/instance"')

for file in $1 $2; do
  yq d -i $file 'metadata.annotations."kubectl.kubernetes.io/last-applied-configuration"'
  yq d -i $file 'metadata.managedFields'
  yq d -i $file 'status'
  yq d -i $file 'metadata.creationTimestamp'
  yq d -i $file 'metadata.resourceVersion'
  yq d -i $file 'metadata.selfLink'
  yq d -i $file 'metadata.uid'
done

# Compute and format diff
diff=$(mktemp)
diff -u9999999 $* | tail -n +4 > $diff
ret=${PIPESTATUS[0]}

if [ $ret -eq 1 ]; then
  echo '```diff'
  cat $diff
  echo '```'
else
  echo "*No differences*" > /dev/null
fi

# If diff is about an argocd App we can add a link to app diff
if [ "$apiVersion/$kind" = "argoproj.io/v1alpha1/Application" ]; then
  if [ "$name" != "$parent_app" ]; then # Avoid endless loop
    echo "Go to [$name diff](#$name)"
  fi
fi

exit $ret
