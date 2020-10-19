ARGOCD_VERSION := 1.7.6
TERRAFORM_VERSION := 0.13.4

CONTAINER_PLATFORM ?= k3s
FLAVOUR ?= _
PROVIDER ?= docker

DISTRIBUTION := $(CONTAINER_PLATFORM)/$(FLAVOUR)/$(PROVIDER)

DOCKER_HOST := "tcp://127.0.0.1:2376/"
UID_NUMBER := $(shell id -u $$USER)
GID_NUMBER := $(shell id -g $$USER)
DOCKER_GID_NUMBER := $(shell stat -c %g /var/run/docker.sock)

DOCKER_COMMON_ARGS := --user $(UID_NUMBER):$(GID_NUMBER) --group-add $(DOCKER_GID_NUMBER) --network host --env HOME=/tmp --entrypoint "" --workdir $$PWD --volume $$PWD:$$PWD

ifneq ($(CI_PROJECT_URL),)
REPO_URL = $(CI_PROJECT_URL)
REMOTE_BRANCH = $(CI_COMMIT_REF_NAME)
else
ifneq ($(GITHUB_SERVER_URL),)
REPO_URL = "$(GITHUB_SERVER_URL)/$(GITHUB_REPOSITORY).git"
REMOTE_BRANCH = $(shell echo $(GITHUB_REF) | rev | cut -f1 -d/ | rev)
else
REMOTE := $(shell git status -sb|sed -Ene's@.. ([^\.]*)\.\.\.([^/]*)/(.*)@\2@p')
REMOTE_BRANCH := $(shell git status -sb|sed -Ene's@.. ([^\.]*)\.\.\.([^/]*)/(.*)@\3@p'|cut -f1 -d' ')
REMOTE_URL := $(shell git remote get-url $(REMOTE))
ifeq ($(findstring "https",$(REMOTE_URL)),)
REPO_URL = "https://github.com/$(shell echo $(REMOTE_URL) | sed -Ene's|git@github.com:([^/]*)/(.*).git|\1/\2|p').git"
else
REPO_URL = $(REMOTE_URL)
endif
endif
endif

CLUSTER_NAME := $(REMOTE_BRANCH)
ARTIFACTS_DIR := "$$PWD/distributions/$(DISTRIBUTION)/terraform/terraform.tfstate.d/$(CLUSTER_NAME)"

.PHONY: test deploy clean debug

test: deploy
	docker run --rm \
		$(DOCKER_COMMON_ARGS) \
		--env BASE_DOMAIN=$(BASE_DOMAIN) \
		curlimages/curl $$PWD/scripts/test.sh

deploy: $(ARTIFACTS_DIR)/kubeconfig.yaml get-base-domain
	docker run --rm \
		$(DOCKER_COMMON_ARGS) \
		-v $(ARTIFACTS_DIR)/kubeconfig.yaml:/tmp/.kube/config \
		--env KUBECTL_COMMAND=apply \
		--env ARGOCD_OPTS="--plaintext --port-forward --port-forward-namespace argocd" \
		--env ARTIFACTS_DIR=$(ARTIFACTS_DIR) \
		argoproj/argocd:v$(ARGOCD_VERSION) $$PWD/scripts/deploy.sh & \
	docker run --rm \
		$(DOCKER_COMMON_ARGS) \
		-v /var/run/docker.sock:/var/run/docker.sock \
		-v $(ARTIFACTS_DIR)/kubeconfig.yaml:/tmp/.kube/config \
		--env VAULT_ADDR="https://vault.apps.$(BASE_DOMAIN)" \
		--env CLUSTER_NAME=$(CLUSTER_NAME) \
		--env ARTIFACTS_DIR=$(ARTIFACTS_DIR) \
		hashicorp/terraform:$(TERRAFORM_VERSION) $$PWD/scripts/configure-vault.sh & \
	wait

# Get kubernetes context
$(ARTIFACTS_DIR)/kubeconfig.yaml: $(ARTIFACTS_DIR)/terraform.tfstate
	CLUSTER_NAME=$(CLUSTER_NAME) ARTIFACTS_DIR=$(ARTIFACTS_DIR) distributions/$(DISTRIBUTION)/scripts/get-kubeconfig.sh

get-base-domain:
	$(eval BASE_DOMAIN = $(shell ARTIFACTS_DIR=$(ARTIFACTS_DIR) distributions/$(DISTRIBUTION)/scripts/get-base-domain.sh))

$(ARTIFACTS_DIR)/terraform.tfstate: distributions/$(DISTRIBUTION)/terraform/*
	echo $(REPO_URL)
	docker run --rm \
		$(DOCKER_COMMON_ARGS) \
		-v /var/run/docker.sock:/var/run/docker.sock \
		--env DISTRIBUTION=$(DISTRIBUTION) \
		--env REPO_URL=$(REPO_URL) \
		--env CLUSTER_NAME=$(CLUSTER_NAME) \
		--env ARTIFACTS_DIR=$(ARTIFACTS_DIR) \
		hashicorp/terraform:$(TERRAFORM_VERSION) $$PWD/scripts/provision.sh

clean: get-base-domain
	docker run --rm \
		$(DOCKER_COMMON_ARGS) \
		-v /var/run/docker.sock:/var/run/docker.sock \
		-v $(ARTIFACTS_DIR)/kubeconfig.yaml:/tmp/.kube/config \
		--env VAULT_ADDR="https://vault.apps.$(BASE_DOMAIN)" \
		--env DISTRIBUTION=$(DISTRIBUTION) \
		--env CLUSTER_NAME=$(CLUSTER_NAME) \
		hashicorp/terraform:$(TERRAFORM_VERSION) $$PWD/scripts/destroy.sh
	rm -rf $(ARTIFACTS_DIR)

debug: get-base-domain
	@echo DISTRIBUTION=$(DISTRIBUTION)
	@echo CLUSTER_NAME=$(CLUSTER_NAME)
	@echo BASE_DOMAIN=$(BASE_DOMAIN)
	@echo DOCKER_HOST=$(DOCKER_HOST)
	@echo UID_NUMBER=$(UID_NUMBER)
	@echo GID_NUMBER=$(GID_NUMBER)
	@echo DOCKER_GID_NUMBER=$(DOCKER_GID_NUMBER)
	@echo ARTIFACTS_DIR=$(ARTIFACTS_DIR)
	@echo REMOTE=$(REMOTE)
	@echo REMOTE_BRANCH=$(REMOTE_BRANCH)
	@echo REMOTE_URL=$(REMOTE_URL)
	@echo REPO_URL=$(REPO_URL)
