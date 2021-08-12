# Changelog

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
