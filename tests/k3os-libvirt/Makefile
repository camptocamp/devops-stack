CLUSTER_NAME := default

REMOTE := $(shell git status -sb|sed -Ene's@.. ([^\.]*)\.\.\.([^/]*)/(.*)@\2@p')
TARGET_REVISION := $(shell git status -sb|sed -Ene's@.. ([^\.]*)\.\.\.([^/]*)/(.*)@\3@p'|cut -f1 -d' ')
REMOTE_URL := $(shell git remote get-url $(REMOTE))
ifeq ($(findstring "https",$(REMOTE_URL)),)
REPO_URL = "https://github.com/$(shell echo $(REMOTE_URL) | sed -Ene's|git@github.com:([^/]*)/(.*).git|\1/\2|p').git"
else
REPO_URL = $(REMOTE_URL)
endif

.PHONY: provision dry-run app-diff clean debug

provision: terraform/*.tf
	CLUSTER_NAME=$(CLUSTER_NAME) TF_VAR_repo_url=$(REPO_URL) TF_VAR_target_revision=$(TARGET_REVISION) ../../scripts/provision.sh

dry-run: terraform/*.tf
	CLUSTER_NAME=$(CLUSTER_NAME) TF_VAR_repo_url=$(REPO_URL) TF_VAR_target_revision=$(TARGET_REVISION) ../../scripts/plan.sh

app-diff: argocd/*
	KUBECONFIG=terraform/kubeconfig.yaml ../../scripts/app-diff.sh

clean:
	CLUSTER_NAME=$(CLUSTER_NAME) TF_VAR_repo_url=$(REPO_URL) TF_VAR_target_revision=$(TARGET_REVISION) ../../scripts/destroy.sh

debug:
	@echo CLUSTER_NAME=$(CLUSTER_NAME)
	@echo REPO_URL=$(REPO_URL)
	@echo TARGET_REVISION=$(TARGET_REVISION)
