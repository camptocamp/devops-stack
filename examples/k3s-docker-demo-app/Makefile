CLUSTER_NAME := default
REPO_URL := https://github.com/camptocamp/camptocamp-devops-stack.git
TARGET_REVISION := master

SCRIPT_PATH := $(shell echo $(REPO_URL) | sed "s@https://github.com/\(.*\)\.git@https://raw.githubusercontent.com/\1/$(TARGET_REVISION)@")

.PHONY: provision clean

provision: terraform/*.tf
	curl $(SCRIPT_PATH)/scripts/provision.sh | CLUSTER_NAME=$(CLUSTER_NAME) sh

clean:
	curl $(SCRIPT_PATH)/scripts/destroy.sh | CLUSTER_NAME=$(CLUSTER_NAME) sh
