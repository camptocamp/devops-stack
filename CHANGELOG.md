# Changelog

## [0.44.0](https://www.github.com/camptocamp/devops-stack/compare/v0.43.0...v0.44.0) (2021-08-26)


### ⚠ BREAKING CHANGES

* **argocd:** upgrade ArgoCD charts and use new repositories spec (#741)

### Features

* **argocd:** upgrade ArgoCD charts and use new repositories spec ([#741](https://www.github.com/camptocamp/devops-stack/issues/741)) ([d4979c7](https://www.github.com/camptocamp/devops-stack/commit/d4979c7808ccddecbda1a5bb431a05bc2f4428ff))
* **k3s:** upgrade camptocamp/k3s/docker module ([0c419db](https://www.github.com/camptocamp/devops-stack/commit/0c419dbce706c12018d0bed6f3fe670d0d76bd7b))
* **k3s:** upgrade K3s to 1.20.10+k3s1 ([6477ac6](https://www.github.com/camptocamp/devops-stack/commit/6477ac6be446392d8fa87a8823968125395574cf))

## [0.43.0](https://www.github.com/camptocamp/devops-stack/compare/v0.42.0...v0.43.0) (2021-08-24)


### Features

* **aks:** set kubernetes version to current default ([4580f26](https://www.github.com/camptocamp/devops-stack/commit/4580f2631b70da36a71b73c0acae8aa386fd6dcd))
* **aks:** upgrade Azure/aks/azurerm module to 4.13.0 ([f47168c](https://www.github.com/camptocamp/devops-stack/commit/f47168c796fee935b36c7afacad5527ef2c9ce87))
* **argocd:** upgrade to v2.1.0 ([3479d25](https://www.github.com/camptocamp/devops-stack/commit/3479d2569d30c9eb71dcefa95244babc9758d712))
* **csi-secrets-store-provider-azure:** upgrade to 0.2.0 ([9a86472](https://www.github.com/camptocamp/devops-stack/commit/9a86472dd102c114f3e1df360870db9bd00c2ac3))
* **sks:** add experimental SKS support ([7e5e929](https://www.github.com/camptocamp/devops-stack/commit/7e5e9294b675c01bd8ac211c242e6cdcbc57ee5c))

## [0.42.0](https://www.github.com/camptocamp/devops-stack/compare/v0.41.2...v0.42.0) (2021-08-19)


### Features

* **aad-pod-identity:** create identities Namespaces ([0358f2d](https://www.github.com/camptocamp/devops-stack/commit/0358f2d5ad55e42892d41a053150b99f8a088375))
* **argocd-applicationset:** upgrade chart version to 1.0.0 ([16fee9d](https://www.github.com/camptocamp/devops-stack/commit/16fee9d65a4310141c0d9b8932cfe5de393a1e9d))
* **argocd-notifications:** upgrade chart version to 1.4.1 ([da3f52c](https://www.github.com/camptocamp/devops-stack/commit/da3f52c5722c88660d7d40241f9991aae1df0344))
* **argocd:** upgrade to v2.0.5 ([f467290](https://www.github.com/camptocamp/devops-stack/commit/f467290c965de75f7d7580da52d71dbb886cbc4b))
* **k3s-docker:** add registry mirror for ghcr.io ([2d26d03](https://www.github.com/camptocamp/devops-stack/commit/2d26d0325478e59ec1d07fd8c24066a1843aa8cd))
* **kube-prometheus-stack:** upgrade to 17.2.1 ([e065fd6](https://www.github.com/camptocamp/devops-stack/commit/e065fd65cfe1730fc94c2d1b7d98b9f45dd6aa18))
* **kube-prometheus-stack:** upgrade to v18.0.0 ([3a299ed](https://www.github.com/camptocamp/devops-stack/commit/3a299edb4aebdd417903c153f355630b7b6e7f8b))
* **loki:** upgrade v2.2.0 ([55ca7e2](https://www.github.com/camptocamp/devops-stack/commit/55ca7e242382ac82fc49e32100b9a53b90812739))
* set CreateNamespace=true syncOption ([53bcc64](https://www.github.com/camptocamp/devops-stack/commit/53bcc649b5d16af7b58c56465a5c8bd9cbc0b3ac))
* **terraform:** upgrade to v1.0.4 ([d2984e4](https://www.github.com/camptocamp/devops-stack/commit/d2984e418a541824d1960e1346a42251d0d6852b))
* **traefik:** upgrade to 2.4.13 ([f26a32e](https://www.github.com/camptocamp/devops-stack/commit/f26a32e25464f0572035bf8b72b2524128218466))


### Bug Fixes

* add missing pathType in Ingress ([f22de25](https://www.github.com/camptocamp/devops-stack/commit/f22de25f6f3629e5d15eb1c6fd21526b54538a7d))
* upgrade k3s/docker module ([774f3e7](https://www.github.com/camptocamp/devops-stack/commit/774f3e7c61465eadc54c1c634420d4b6c247fe94))

### [0.41.2](https://www.github.com/camptocamp/devops-stack/compare/v0.41.1...v0.41.2) (2021-08-12)


### Bug Fixes

* fix weird character in template ([6c903c3](https://www.github.com/camptocamp/devops-stack/commit/6c903c34706b21050adc1a3446e7ea374bbad419))

### [0.41.1](https://www.github.com/camptocamp/devops-stack/compare/v0.41.0...v0.41.1) (2021-08-12)


### Bug Fixes

* **eks:** pass missing arg to function ([5b72586](https://www.github.com/camptocamp/devops-stack/commit/5b725867cd2ef5e95bb148b2cfe678d932843ce8))

## [0.41.0](https://www.github.com/camptocamp/devops-stack/compare/v0.40.0...v0.41.0) (2021-08-11)


### Features

* add http01 solver for acme for AKS and EKS ([ff3188c](https://www.github.com/camptocamp/devops-stack/commit/ff3188c567db0061a4a12412241e49addef3b28a))
* add Release Please Action ([aa781ec](https://www.github.com/camptocamp/devops-stack/commit/aa781ecf3b2d8e25fdcca465a1bd9af4165998c4))
* **cert-manager:** upgrade cert-manager to v1.4.3 ([3bc9c77](https://www.github.com/camptocamp/devops-stack/commit/3bc9c77616d45c13b85daa2a21b01206683b8be6))
* **eks:** expose map_accounts and map_users arguments ([501e3b5](https://www.github.com/camptocamp/devops-stack/commit/501e3b5c417715de2c973767ef773043bac201c1))
* enable support for network policy in azure ([ff14031](https://www.github.com/camptocamp/devops-stack/commit/ff14031467ab0a6eb6f6a284f906858397ed39f7))
* **grafana:** set default users role to Editor ([cd95c03](https://www.github.com/camptocamp/devops-stack/commit/cd95c03dbf73a41c88fd811fe093ab18afe96da2))
* **k3s-libvirt:** upgrade k3os to v0.20.7-k3s1r0 ([873c72b](https://www.github.com/camptocamp/devops-stack/commit/873c72b2553b11d5dde1335230546a4b43c9120e))
* **k3s:** add Keycloak's admin password to Terraform outputs ([305eb67](https://www.github.com/camptocamp/devops-stack/commit/305eb670b5ea70c650eaf25a849ddb293c95a2a6))
* **keycloak:** use embedded H2 database for Keycloak ([1c52e9b](https://www.github.com/camptocamp/devops-stack/commit/1c52e9b02059b7037bad8512c241c1d8cdcd61e1))


### Bug Fixes

* AWS: Filter DNS challenge only on base domain ([e76fd3b](https://www.github.com/camptocamp/devops-stack/commit/e76fd3b8d9e553c07c41876562cdd1fa1f96708b))
* Azure: Filter DNS challenge only on base domain ([687629e](https://www.github.com/camptocamp/devops-stack/commit/687629e7412127a27c807f320e692daef6536e9d)), closes [#700](https://www.github.com/camptocamp/devops-stack/issues/700)
* **k3s:** add missing cluster name in URLs ([093919b](https://www.github.com/camptocamp/devops-stack/commit/093919b5361cff0b64091d239d3db28e3cde68cc))
* selector in same block ([d53cd33](https://www.github.com/camptocamp/devops-stack/commit/d53cd33c593e85e3a0e69482617aced675a4be69))
