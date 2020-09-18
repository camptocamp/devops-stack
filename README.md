Camptocamp's Kubernetes Demo
============================

This is a demo that is also reference implementation for all our Kubernetes related projects.

Provisioning
------------

This demo will start a [Rancher](https://www.rancher.com)'s [K3s](https://github.com/rancher/k3s) cluster locally using [HashiCorp](https://www.hashicorp.com/)'s [Terraform](https://www.terraform.io/).

### Why K3s?

K3s allows to create a lightweight Kubernetes cluster on any workstation.
This is very convenient for developing or testing purpose.

### Why Terraform

As we already use Terraform to deploy our other Kubernetes clusters, such as EKS, AKS, OpenShift on different cloud, it looks natural to also use Terraform to deploy a K3s cluster locally.
