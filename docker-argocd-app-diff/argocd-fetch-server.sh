check_connection () {
  (echo > /dev/tcp/$(echo $ARGOCD_SERVER | tr ':' '/') ) 2>/dev/null
  return $?
}

check_app_list () {
  argocd app list >/dev/null 2>&1
  return $?
}

if [ -z "$ARGOCD_SERVER" ]; then
  # First try with the k8s service
  echo "Search for 'argocd' service in 'argocd' namespace"
  kubectl get -n argocd service arogcd >/dev/null 2>&1 && export ARGOCD_SERVER=argocd.argocd.svc:443
  echo "Search for 'argocd-server' service in 'argocd' namespace"
  kubectl get -n argocd service argocd-server >/dev/null 2>&1 && export ARGOCD_SERVER=argocd-server.argocd.svc:443

  # Check connection
  if check_connection; then
    echo "ArgoCD is available on $ARGOCD_SERVER"
  else
    echo "Cannot contact ArgoCD with service, not running in cluster"

    # Try with ingress or route
    echo "Search for ingress 'argocd' namespace"
    ingress_host=$(kubectl get ingress -n argocd -o yaml 2>/dev/null | yq r - 'items[*].spec.host')
    echo "Search for route 'argocd' namespace"
    route_host=$(kubectl get route -n argocd -o yaml  2>/dev/null | yq r - 'items[*].spec.host')
    [ -n "$ingress_host" ] && export ARGOCD_SERVER=$ingress_host:443
    [ -n "$route_host" ] && export ARGOCD_SERVER=$route_host:443

    if check_connection; then
      echo "ArgoCD is available on $ARGOCD_SERVER"
    else
      echo "Cannot connect to  ArgoCD"
      echo exit 1
    fi
  fi
fi

# Try secure connection
if check_app_list; then
  echo "Using Secure connection to $ARGOCD_SERVER"
else
  # Try insecure connection
  if [ "$AAD_ARGOCD_ALLOW_INSECURE" = "true" ]; then
    export ARGOCD_OPTS="--insecure"
    if check_app_list; then
      echo "Using *insecure* connection to $ARGOCD_SERVER"
    else
      echo "Cannot connect to argocd with insecure connection:"
      argocd app list
    fi
  else
    echo -n "Insecure connection to ArgoCD are not allowed, "
    echo "set AAD_ARGOCD_ALLOW_INSECURE to 'true' to allow insecrure connection"
    echo exit 1
  fi
fi
