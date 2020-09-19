CLUSTER_NAME := $(shell git name-rev --name-only HEAD)
BASE_DOMAIN := 127-0-0-1.nip.io

DOCKER_HOST := "tcp://127.0.0.1:2376/"
UID_NUMBER := $(shell id -u $$USER)
GID_NUMBER := $(shell id -g $$USER)
DOCKER_GID_NUMBER := $(shell stat -c %g /var/run/docker.sock)
ARTIFACTS_DIR := "terraform/terraform.tfstate.d/$(CLUSTER_NAME)"

ifneq ($(CI_PROJECT_URL),)
REPO_URL = $(CI_PROJECT_URL)
else
ifneq ($(GITHUB_SERVER_URL),)
REPO_URL = "$(GITHUB_SERVER_URL)/$(GITHUB_REPOSITORY).git"
else
ifeq ($(findstring "https",$(shell git config --get remote.origin.url)),)
REPO_URL = "https://github.com/$(shell git config --get remote.origin.url | sed -Ene's#git@github.com:([^/]*)/(.*).git#\1/\2#p').git"
else
REPO_URL = $(shell git config --get remote.origin.url)
endif
endif
endif

.PHONY: test deploy clean debug

test: deploy
	docker run --rm \
		--user $(UID_NUMBER):$(GID_NUMBER) \
		-v $$PWD:/workdir \
		--network host \
		--env CLUSTER_NAME=$(CLUSTER_NAME) \
		--env BASE_DOMAIN=$(BASE_DOMAIN) \
		--env HOME=/tmp \
		--entrypoint "" \
		--workdir /workdir \
		curlimages/curl /workdir/scripts/test.sh

deploy: $(ARTIFACTS_DIR)/kubeconfig.yaml
	docker run --rm \
		--user $(UID_NUMBER):$(GID_NUMBER) \
		-v $$PWD:/workdir \
		-v $$PWD/$(ARTIFACTS_DIR)/kubeconfig.yaml:/tmp/.kube/config \
		--network host \
		--env HOME=/tmp \
		--env KUBECTL_COMMAND=apply \
		--env ARGOCD_OPTS="--plaintext --port-forward --port-forward-namespace argocd" \
		--env ARTIFACTS_DIR=$(ARTIFACTS_DIR) \
		--entrypoint "" \
		--workdir /workdir \
		argoproj/argocd:v1.6.2 /workdir/scripts/deploy.sh

$(ARTIFACTS_DIR)/kubeconfig.yaml: terraform/*
	echo $(REPO_URL)
	touch $$HOME/.terraformrc
	docker run --rm \
		--group-add $(DOCKER_GID_NUMBER) \
		--user $(UID_NUMBER):$(GID_NUMBER) \
		-v /var/run/docker.sock:/var/run/docker.sock \
		-v $$PWD:/workdir \
		-v $$HOME/.terraformrc:/tmp/.terraformrc \
		-v $$HOME/.terraform.d:/tmp/.terraform.d \
		--env HOME=/tmp \
		--env TF_VAR_k3s_kubeconfig_dir=$$PWD/$(ARTIFACTS_DIR) \
		--env REPO_URL=$(REPO_URL) \
		--env CLUSTER_NAME=$(CLUSTER_NAME) \
		--env ARTIFACTS_DIR=$(ARTIFACTS_DIR) \
		--entrypoint "" \
		--workdir /workdir \
		hashicorp/terraform:0.13.3 /workdir/scripts/provision.sh

clean:
	touch $$HOME/.terraformrc
	docker run --rm \
		--group-add $(DOCKER_GID_NUMBER) \
		--user $(UID_NUMBER):$(GID_NUMBER) \
		-v /var/run/docker.sock:/var/run/docker.sock \
		-v $$PWD:/workdir \
		-v $$HOME/.terraformrc:/tmp/.terraformrc \
		-v $$HOME/.terraform.d:/tmp/.terraform.d \
		--env HOME=/tmp \
		--env TF_VAR_k3s_kubeconfig_dir=$$PWD \
		--env CLUSTER_NAME=$(CLUSTER_NAME) \
		--entrypoint "" \
		--workdir /workdir \
		hashicorp/terraform:0.13.3 /workdir/scripts/destroy.sh
	rm -rf $$PWD/$(ARTIFACTS_DIR)

debug:
	@echo CLUSTER_NAME=$(CLUSTER_NAME)
	@echo BASE_DOMAIN=$(BASE_DOMAIN)
	@echo DOCKER_HOST=$(DOCKER_HOST)
	@echo UID_NUMBER=$(UID_NUMBER)
	@echo GID_NUMBER=$(GID_NUMBER)
	@echo DOCKER_GID_NUMBER=$(DOCKER_GID_NUMBER)
	@echo ARTIFACTS_DIR="terraform/terraform.tfstate.d/$(CLUSTER_NAME)"
	@echo REPO_URL=$(REPO_URL)
