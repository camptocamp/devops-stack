#/bin/bash

[ "$DEBUG" = "true" ] && set -xe

# TODO lock argocd by deploying a configmap that contains pipeline ID with kubectl *create*
# 1. Disable auto sync and use feature branch for argocd
echo ""
echo "Disable Auto-Sync and switch to ${AAD_FEATURE_BRANCH} branch"
echo "------------------------------------------------------------"
$(dirname $0)/argocd-switch-to-feature-branch.sh ${AAD_ROOT_APP} ${AAD_FEATURE_BRANCH}

# 2. Run app diff on top level app of apps
# * Display diff
# * Deploy any Application
# * Run App Diff in all Application (new, modified, ...)
echo ""
echo "Compute Diff"
echo "------------"
$(dirname $0)/recursive-diff.sh ${AAD_ROOT_APP} || true

# 3. Revert modification
echo ""
echo "Rollback ArgoCD to ${AAD_TARGET_BRANCH}"
echo "----------------------------------"
$(dirname $0)/argocd-re-sync.sh ${AAD_ROOT_APP} ${AAD_TARGET_BRANCH}
