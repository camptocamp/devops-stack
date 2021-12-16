# Changelog

## [0.51.0](https://www.github.com/camptocamp/devops-stack/compare/v0.50.4...v0.51.0) (2021-12-14)


### Features

* **aks:** enable parametrization of storage account used by loki ([#835](https://www.github.com/camptocamp/devops-stack/issues/835)) ([0be4796](https://www.github.com/camptocamp/devops-stack/commit/0be4796e2574b172fd56b1c083eff18c4e39b17c))

### [0.50.4](https://www.github.com/camptocamp/devops-stack/compare/v0.50.3...v0.50.4) (2021-12-08)


### Bug Fixes

* **website:** build on released ([#833](https://www.github.com/camptocamp/devops-stack/issues/833)) ([df08655](https://www.github.com/camptocamp/devops-stack/commit/df08655d842f9ddd0e5497742f1eb61d7076e520))

### [0.50.3](https://www.github.com/camptocamp/devops-stack/compare/v0.50.2...v0.50.3) (2021-12-08)


### Bug Fixes

* **website:** build on published ([#831](https://www.github.com/camptocamp/devops-stack/issues/831)) ([d5a31d2](https://www.github.com/camptocamp/devops-stack/commit/d5a31d29461d4cb89b8adbcdffe55194abc3358c))

### [0.50.2](https://www.github.com/camptocamp/devops-stack/compare/v0.50.1...v0.50.2) (2021-12-07)


### Bug Fixes

* **website:** build website on release published ([#829](https://www.github.com/camptocamp/devops-stack/issues/829)) ([bc52f82](https://www.github.com/camptocamp/devops-stack/commit/bc52f82813f4d3b7f4d85103fdaca9acb5d8d36d))

### [0.50.1](https://www.github.com/camptocamp/devops-stack/compare/v0.50.0...v0.50.1) (2021-12-07)


### Bug Fixes

* **docs:** add kubectl note ([#827](https://www.github.com/camptocamp/devops-stack/issues/827)) ([b955051](https://www.github.com/camptocamp/devops-stack/commit/b9550517e755c7b5d48f80a121f3a73447cadf58))
* **docs:** remove cgroupv2 note ([#825](https://www.github.com/camptocamp/devops-stack/issues/825)) ([97e3437](https://www.github.com/camptocamp/devops-stack/commit/97e34374e5eb32f140c89725ace8101b75bdc5d9))

## [0.50.0](https://www.github.com/camptocamp/devops-stack/compare/v0.49.0...v0.50.0) (2021-12-03)


### Features

* **docs:** improve KinD docs ([#820](https://www.github.com/camptocamp/devops-stack/issues/820)) ([62fab9f](https://www.github.com/camptocamp/devops-stack/commit/62fab9f89260a1d4938688afa1e29133aa93d988))
* enable using url without cluster name ([#823](https://www.github.com/camptocamp/devops-stack/issues/823)) ([7728b0f](https://www.github.com/camptocamp/devops-stack/commit/7728b0f87c14023d89996d2e2b99c3b5dd7ea4ef))

## [0.49.0](https://www.github.com/camptocamp/devops-stack/compare/v0.48.0...v0.49.0) (2021-11-19)


### ⚠ BREAKING CHANGES

* **eks:** send http traffic on NLB to port 80 on cluster (#810)

### Features

* **keycloak:** pass a user list to keycloak ([#788](https://www.github.com/camptocamp/devops-stack/issues/788)) ([c2835ec](https://www.github.com/camptocamp/devops-stack/commit/c2835ecaba5ffb02908fa77049cffecb976787e3))
* **kind:** add experimental support for KIND ([#785](https://www.github.com/camptocamp/devops-stack/issues/785)) ([518e3e6](https://www.github.com/camptocamp/devops-stack/commit/518e3e6885082429298607314215e15fcacb0d07))
* **sks:** add output for cluster security group id ([#816](https://www.github.com/camptocamp/devops-stack/issues/816)) ([de31691](https://www.github.com/camptocamp/devops-stack/commit/de31691b49cdafd7236d8a0395d2af2b8bc30d23))
* **traefik:** tls version >= 1.2 ([#793](https://www.github.com/camptocamp/devops-stack/issues/793)) ([c49580e](https://www.github.com/camptocamp/devops-stack/commit/c49580efa834d1a5001abb18f0d9cf120970efc3))


### Bug Fixes

* **argocd:** fix kube-prometheus-stack dependency on OIDC ([#795](https://www.github.com/camptocamp/devops-stack/issues/795)) ([5848af8](https://www.github.com/camptocamp/devops-stack/commit/5848af8970a8c273b8243fae3f5dd98167af17d2))
* **eks:** keycloak admin pass output when not installed ([#817](https://www.github.com/camptocamp/devops-stack/issues/817)) ([980979b](https://www.github.com/camptocamp/devops-stack/commit/980979b1f4ab443a6689f6fbce8845b24bebd70f))
* **eks:** send http traffic on NLB to port 80 on cluster ([#810](https://www.github.com/camptocamp/devops-stack/issues/810)) ([0cbd0eb](https://www.github.com/camptocamp/devops-stack/commit/0cbd0eb05fcb818a623fa70489ad6b5f9302198b))

## [0.48.0](https://www.github.com/camptocamp/devops-stack/compare/v0.47.0...v0.48.0) (2021-09-22)


### Features

* **aks:** add kubelet identity to outputs ([f883650](https://www.github.com/camptocamp/devops-stack/commit/f883650310fbd6e6828af4531d9ddf1855599653))
* **aks:** extend accepted params for node pools ([#780](https://www.github.com/camptocamp/devops-stack/issues/780)) ([831557f](https://www.github.com/camptocamp/devops-stack/commit/831557fe323b2bb90ae70685c6b4c0cd0fe9de6c))
* **docs:** add SKS quickstart ([#784](https://www.github.com/camptocamp/devops-stack/issues/784)) ([e26a5f1](https://www.github.com/camptocamp/devops-stack/commit/e26a5f18fab283b35548629eac2d9b3b2b9e2275))


### Bug Fixes

* **aks:** use local.base_domain instead of var.base_domain ([c417678](https://www.github.com/camptocamp/devops-stack/commit/c417678e34b31011def356998dba864668a5cf59))
* **doc:** homogenize name 'DevOps Stack' ([95c9e82](https://www.github.com/camptocamp/devops-stack/commit/95c9e82449bba7f758dec0ebb9be46d8d481fa3b))

## [0.47.0](https://www.github.com/camptocamp/devops-stack/compare/v0.46.0...v0.47.0) (2021-09-15)


### Features

* **keycloak:** rename client to devops-stack-applications ([ead90c7](https://www.github.com/camptocamp/devops-stack/commit/ead90c7502e23fb1b23fcf20478cd07c225cd943))
* **keycloak:** upgrade to v15.0.1 ([c7dfdbb](https://www.github.com/camptocamp/devops-stack/commit/c7dfdbb9a998729b090168d1fa0405f4d3ee5666))
* **loki-stack:** add monitoring when filebeat logging is enabled ([5038df4](https://www.github.com/camptocamp/devops-stack/commit/5038df422e4f0dbdc2594ce5735876d090476119))


### Bug Fixes

* **keycloak:** add missing scopes to client ([a86403b](https://www.github.com/camptocamp/devops-stack/commit/a86403b086af1fb518ce739235516423a5ae36cb))

## [0.46.0](https://www.github.com/camptocamp/devops-stack/compare/v0.45.0...v0.46.0) (2021-09-10)


### Features

* Add initial support for OpenTelekomCloud's CCE ([a7e374b](https://www.github.com/camptocamp/devops-stack/commit/a7e374bdae98da58548902f2ef80c49b104e0394))
* **aks:** add support for node pools in AKS ([edb9813](https://www.github.com/camptocamp/devops-stack/commit/edb981339ef566e21ae16338bc7e6c17699da9d9))
* allow to disable wait_for_app_of_apps ([a01303b](https://www.github.com/camptocamp/devops-stack/commit/a01303bcce252e40a2cf063d7fb2bd58aa4e58c2))
* **antora:** use lunr generator in github action for building documentation search index ([2307150](https://www.github.com/camptocamp/devops-stack/commit/23071502923435ac4aef026858f3ae3f49aa748b))
* **aws:** add test example ([7ddef46](https://www.github.com/camptocamp/devops-stack/commit/7ddef46ae4c07d57bea85355059bb7980adb5c63))
* **aws:** use nip.io by default ([947380c](https://www.github.com/camptocamp/devops-stack/commit/947380c9a2db763d380e3e11cc7d9384bbee4978))
* **keycloak:** rename user=admin to user=jdoe ([7ad68c5](https://www.github.com/camptocamp/devops-stack/commit/7ad68c5314a1073e5dd6dc04eaca2b418d4585ed))
* randomize argocd admin password ([1cf91f0](https://www.github.com/camptocamp/devops-stack/commit/1cf91f0aee30d369bc8ea8d0ad2a43c714c18a70))
* **sks:** add node anti-affinity on router nodes for cert-manager ([#753](https://www.github.com/camptocamp/devops-stack/issues/753)) ([dc3a4a3](https://www.github.com/camptocamp/devops-stack/commit/dc3a4a35f6b1250d852440d165b3775ce700aa6d))
* **sks:** add output for nlb ip address ([35d4ba9](https://www.github.com/camptocamp/devops-stack/commit/35d4ba9cca1a022eaecad63a3083659fe72c0132))
* **sks:** use Kubernetes 1.21.4 by default ([a95d813](https://www.github.com/camptocamp/devops-stack/commit/a95d8135e962a03bf2a12845815af1af94cc2469))
* **sks:** use letsencrypt-prod when there is more than 1 node pool ([#754](https://www.github.com/camptocamp/devops-stack/issues/754)) ([0f8179c](https://www.github.com/camptocamp/devops-stack/commit/0f8179c0d83654442e658ead302ffd5f995a563d))


### Bug Fixes

* **argocd:** fix health assessment for Applications ([c7a46cb](https://www.github.com/camptocamp/devops-stack/commit/c7a46cbe0b3aa4cc134c0e20bd034a883c146e3f))
* **aws:** don't add nat gateway to cluster_endpoint_public_access_cidrs by default ([54625b0](https://www.github.com/camptocamp/devops-stack/commit/54625b04199b9c9920d5bed9b43c769018093a5b))
* **aws:** use local.base_domain instead of var.base_domain ([2583e09](https://www.github.com/camptocamp/devops-stack/commit/2583e092b27651bfb60508805b972136825681af))
* format with terraform fmt ([33a499e](https://www.github.com/camptocamp/devops-stack/commit/33a499e2e6f6ec12a75b1d43f402cacbcc409869))
* **sks:** pass down missing variables to argocd-helm ([#748](https://www.github.com/camptocamp/devops-stack/issues/748)) ([97f3973](https://www.github.com/camptocamp/devops-stack/commit/97f397369e558c0b7a32841cedded4027214f8c5))

## [0.45.0](https://www.github.com/camptocamp/devops-stack/compare/v0.44.0...v0.45.0) (2021-08-27)


### Features

* **kube-prometheus-stack:** upgrade chart to 18.0.1 ([#743](https://www.github.com/camptocamp/devops-stack/issues/743)) ([103dfc6](https://www.github.com/camptocamp/devops-stack/commit/103dfc67be8bfd0ee72ebd6fda60507211fdf163))

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
