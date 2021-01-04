check_app_list () {
  argocd app list >/dev/null 2>&1
  return $?
}

default_argocd_opt="--port-forward --port-forward-namespace argocd --config /tmp/$$"

if [ -z "$ARGOCD_SERVER" ]; then
  # First try with port forward and HTTP
  echo "Trying to access argocd with HTTP port-forward..."
  export ARGOCD_OPTS="--plaintext $default_argocd_opt"
  if check_app_list; then
    echo "Using HTTP port-forward connection to ArgoCD"
  else
    # then try with HTTPS
  echo "Trying to access argocd with HTTPS port-forward..."
    export ARGOCD_OPTS="$default_argocd_opt"
    if check_app_list; then
      echo "Using HTTPS port-forward connection to ArgoCD"
    else
      echo "Cannot contact ArgoCD with port-forward"
      echo exit 1
    fi
  fi
fi
