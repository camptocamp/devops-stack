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

ARGOCD_DIR := $$PWD/argocd
DISTRIBUTION_DIR := $$PWD/distributions/$(DISTRIBUTION)
TERRAFORM_DIR := distributions/$(DISTRIBUTION)/terraform
ARTIFACTS_DIR := $(TERRAFORM_DIR)/terraform.tfstate.d/$(CLUSTER_NAME)
SCRIPTS_DIR := $$PWD/scripts
VAULT_DIR := vault

.PHONY: test deploy clean debug get-base-domain

test: deploy get-base-domain
	docker run --rm \
		$(DOCKER_COMMON_ARGS) \
		--env BASE_DOMAIN=$(BASE_DOMAIN) \
		curlimages/curl $(SCRIPTS_DIR)/test.sh

deploy: $(ARTIFACTS_DIR)/kubeconfig.yaml get-base-domain
	docker run --rm \
		$(DOCKER_COMMON_ARGS) \
		--mount type=bind,src=$$PWD/$(ARTIFACTS_DIR)/kubeconfig.yaml,dst=/tmp/.kube/config \
		--env KUBECTL_COMMAND=apply \
		--env ARGOCD_OPTS="--plaintext --port-forward --port-forward-namespace argocd" \
		--env ARTIFACTS_DIR=$(ARTIFACTS_DIR) \
		--env ARGOCD_DIR=$(ARGOCD_DIR) \
		argoproj/argocd:v$(ARGOCD_VERSION) $(SCRIPTS_DIR)/deploy.sh & \
	docker run --rm \
		$(DOCKER_COMMON_ARGS) \
		--mount type=bind,src=/var/run/docker.sock,dst=/var/run/docker.sock \
		--mount type=bind,src=$$PWD/$(ARTIFACTS_DIR)/kubeconfig.yaml,dst=/tmp/.kube/config \
		--env VAULT_ADDR="https://vault.apps.$(BASE_DOMAIN)" \
		--env VAULT_DIR=$(VAULT_DIR) \
		--env CLUSTER_NAME=$(CLUSTER_NAME) \
		--env ARTIFACTS_DIR=$(ARTIFACTS_DIR) \
		hashicorp/terraform:$(TERRAFORM_VERSION) $(SCRIPTS_DIR)/configure-vault.sh & \
	wait

# Get kubernetes context
$(ARTIFACTS_DIR)/kubeconfig.yaml: $(ARTIFACTS_DIR)/terraform.tfstate
	CLUSTER_NAME=$(CLUSTER_NAME) ARTIFACTS_DIR=$(ARTIFACTS_DIR) $(DISTRIBUTION_DIR)/scripts/get-kubeconfig.sh

get-base-domain:
	$(eval BASE_DOMAIN = $(shell ARTIFACTS_DIR=$(ARTIFACTS_DIR) $(DISTRIBUTION_DIR)/scripts/get-base-domain.sh))

$(ARTIFACTS_DIR)/terraform.tfstate: $(TERRAFORM_DIR)/*.tf
	docker run --rm \
		$(DOCKER_COMMON_ARGS) \
		--mount type=bind,src=/var/run/docker.sock,dst=/var/run/docker.sock \
		--env DISTRIBUTION_DIR=$(DISTRIBUTION_DIR) \
		--env TERRAFORM_DIR=$(TERRAFORM_DIR) \
		--env REPO_URL=$(REPO_URL) \
		--env CLUSTER_NAME=$(CLUSTER_NAME) \
		--env TF_VAR_cluster_name=$(CLUSTER_NAME) \
		--env ARTIFACTS_DIR=$(ARTIFACTS_DIR) \
		hashicorp/terraform:$(TERRAFORM_VERSION) $(SCRIPTS_DIR)/provision.sh

clean: get-base-domain
	docker run --rm \
		$(DOCKER_COMMON_ARGS) \
		--mount type=bind,src=/var/run/docker.sock,dst=/var/run/docker.sock \
		--mount type=bind,src=$$PWD/$(ARTIFACTS_DIR)/kubeconfig.yaml,dst=/tmp/.kube/config \
		--env VAULT_ADDR="https://vault.apps.$(BASE_DOMAIN)" \
		--env DISTRIBUTION_DIR=$(DISTRIBUTION_DIR) \
		--env TERRAFORM_DIR=$(TERRAFORM_DIR) \
		--env VAULT_DIR=$(VAULT_DIR) \
		--env CLUSTER_NAME=$(CLUSTER_NAME) \
		--env TF_VAR_cluster_name=$(CLUSTER_NAME) \
		hashicorp/terraform:$(TERRAFORM_VERSION) $(SCRIPTS_DIR)/destroy.sh
	rm -rf $(ARTIFACTS_DIR)

debug: get-base-domain
	@echo DISTRIBUTION=$(DISTRIBUTION)
	@echo CLUSTER_NAME=$(CLUSTER_NAME)
	@echo BASE_DOMAIN=$(BASE_DOMAIN)
	@echo DOCKER_HOST=$(DOCKER_HOST)
	@echo UID_NUMBER=$(UID_NUMBER)
	@echo GID_NUMBER=$(GID_NUMBER)
	@echo DOCKER_GID_NUMBER=$(DOCKER_GID_NUMBER)
	@echo DISTRIBUTION_DIR=$(DISTRIBUTION_DIR)
	@echo TERRAFORM_DIR=$(TERRAFORM_DIR)
	@echo ARGOCD_DIR=$(ARGOCD_DIR)
	@echo VAULT_DIR=$(VAULT_DIR)
	@echo SCRIPTS_DIR=$(SCRIPTS_DIR)
	@echo ARTIFACTS_DIR=$(ARTIFACTS_DIR)
	@echo REMOTE=$(REMOTE)
	@echo REMOTE_BRANCH=$(REMOTE_BRANCH)
	@echo REMOTE_URL=$(REMOTE_URL)
	@echo REPO_URL=$(REPO_URL)
