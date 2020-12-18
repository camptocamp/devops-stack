Compute a diff on ArgoCD apps defined in a
feature branch in a git repository.
This script will simulate deployment of feature
branch and extract diff from argocd.
This script should be run by a pull/merge requests.
Diff will be inserted as comment.

# Configuration

Mandatory:

* KUBECONFIG: Configuration to access cluster

Optional:

* AAD_ROOT_APP: Root app of apps
* AAD_REPO_URL: URL of git repo used to filter apps
* AAD_FEATURE_BRANCH: Feature branch that contains new version of manifests
* AAD_TARGET_BRANCH: Target branch of the pull/merge request
* AAD_ARGOCD_ALLOW_INSECURE: if set to 'true' allow insecure connection to
  ArgoCD
* ARGOCD_SERVER: Force address of ArgoCD, disable auto detection
* ARGOCD_AUTH_TOKEN: Same for token
