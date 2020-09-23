Camptocamp's Kubernetes Demo
============================

This is a demo that is also reference implementation for all our Kubernetes related projects.

TL;DR
-----

### Create a cluster

Just run `make`.

It will:
- spawn a K3s cluster on your workstation using Docker
- deploy ArgoCD in the cluster
- deploy the App of Apps that manages ArgoCD and itself.

### Destroy a cluster

Just run `make clean`.

Provisioning
------------

This demo will start a [Rancher](https://www.rancher.com)'s [K3s](https://github.com/rancher/k3s) cluster locally using [HashiCorp](https://www.hashicorp.com/)'s [Terraform](https://www.terraform.io/).

### Why K3s?

K3s allows to create a lightweight Kubernetes cluster on any workstation.
This is very convenient for developing or testing purpose.

### Why Terraform?

As we already use Terraform to deploy our other Kubernetes clusters, such as EKS, AKS, OpenShift on different cloud, it looks natural to also use Terraform to deploy a K3s cluster locally.

This allows us to use the same `scripts/provision.sh` script, whatever the platform on which we deploy our clusters.

Also, we can use [Terraform workspaces](https://www.terraform.io/docs/state/workspaces.html) to create one cluster per git branch, which is quite convenient for testing.

Deployment
----------

We use [ArgoCD](https://argoproj.github.io/argo-cd/) as continuous delivery tool for Kubernetes.
This allows us to declare all the applications we want to deploy in the cluster.
The `scrips/deploy.sh` script deploys ArgoCD if it detects that it is not present, then deploys the ArgoCD [App of Apps](https://argoproj.github.io/argo-cd/operator-manual/declarative-setup/#app-of-apps) with [Automated Sync Policy](https://argoproj.github.io/argo-cd/user-guide/auto_sync/).

### Why Automated Sync Policy?

At Camptocamp we have a huge experience in both [Puppet](https://puppet.com/) and [Terraform](https://www.terraform.io/).
This two tools use two different paradygm to apply configuration:
- Pull for Puppet: an agent runs every 30 minutes on the server to deploy new configuration and ensure that every drift is fixed within half an hour at top,
- Push for Terraform: as long as nobody really applies a Terraform manifest, nothing is deploy ; hence you code may not reflect what exists.

By experience, we know that it is hard to have hundreds of Terraform workspaces that always converge, hence with think that pull mode better fits GitOps philosophy.

To ensure continuous reconciliation, we enable Automated Sync Policy on our Applications. This forces us to be rigurous.

What can you do with this demo?
-------------------------------

For now not that much, but more stuffs are coming.

### Access Kubernetes API

K3s' installation create a `kubeconfig.yaml` file that contains the Kubernetes context that allows you to access the cluster.

```shell
$ export CLUSTER_NAME=master
$ export KUBECONFIG=terraform/terraform.tfstate.d/$CLUSTER_NAME/kubeconfig.yaml
$ export BASE_DOMAIN=`docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' k3s-agent-$CLUSTER_NAME|tr '.' '-'`.nip.io
$ kubectl get nodes
$ kubectl get namespaces
$ kubectl get pods --all-namespaces
```

### Access ArgoCD web UI

ArgoCD Web UI is accessible via https://argocd.apps.$BASE_DOMAIN.
The default account is admin/argocd.

### Access Traefik dashboard

For security reasons, Traefik dashboard is not exposed, hence you have to use port-forwarding to access it:

```shell
$ kubectl -n traefik port-forward $(kubectl -n traefik get pods --selector "app.kubernetes.io/name=traefik" --output=name) 9000:9000
```

Then point your web browser to http://localhost:9000/dashboard/

### Access Grafana dashboard

Granafa is accessible via https://grafana.apps.$CLUSTER_NAME.$BASE_DOMAIN.
As there is currently no proper secret management in this demo, we let the default Grafana credentials: `admin/prom-operator`.

### Access Prometheus dashboard

Prometheus is accessible via https://prometheus.apps.$CLUSTER_NAME.$BASE_DOMAIN.
As there is currently no proper secret management in this demo, the Prometheus URL is not protected.

### Access Alertmanager dashboard

Alertmanager is accessible via https://alertmanager.apps.$CLUSTER_NAME.$BASE_DOMAIN.
As there is currently no proper secret management in this demo, the Alertmanager URL is not protected.
