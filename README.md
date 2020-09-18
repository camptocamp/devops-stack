Camptocamp's Kubernetes Demo
============================

This is a demo that is also reference implementation for all our Kubernetes related projects.

Provisioning
------------

This demo will start a [Rancher](https://www.rancher.com)'s [K3s](https://github.com/rancher/k3s) cluster locally using [HashiCorp](https://www.hashicorp.com/)'s [Terraform](https://www.terraform.io/).

### Why K3s?

K3s allows to create a lightweight Kubernetes cluster on any workstation.
This is very convenient for developing or testing purpose.

### Why Terraform?

As we already use Terraform to deploy our other Kubernetes clusters, such as EKS, AKS, OpenShift on different cloud, it looks natural to also use Terraform to deploy a K3s cluster locally.

This allows us to use the same `scripts/provision.sh` script, whatever the platform on which we deploy our clusters.

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
