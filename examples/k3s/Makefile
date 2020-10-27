TERRAFORM_VERSION := 0.13.5

CLUSTER_NAME := default

DOCKER_HOST := "tcp://127.0.0.1:2376/"
UID_NUMBER := $(shell id -u $$USER)
GID_NUMBER := $(shell id -g $$USER)
DOCKER_GID_NUMBER := $(shell stat -c %g /var/run/docker.sock)

DOCKER_COMMON_ARGS := --user $(UID_NUMBER):$(GID_NUMBER) --group-add $(DOCKER_GID_NUMBER) --network host --env HOME=/tmp --entrypoint "" --workdir $$PWD --volume $$PWD:$$PWD --mount type=bind,src=/var/run/docker.sock,dst=/var/run/docker.sock --env CLUSTER_NAME=$(CLUSTER_NAME)

.PHONY: provision clean debug

provision: terraform/*.tf
	docker run --rm $(DOCKER_COMMON_ARGS) \
		hashicorp/terraform:$(TERRAFORM_VERSION) scripts/provision.sh

clean:
	docker run --rm $(DOCKER_COMMON_ARGS) \
		hashicorp/terraform:$(TERRAFORM_VERSION) scripts/destroy.sh

debug:
	@echo CLUSTER_NAME=$(CLUSTER_NAME)
	@echo UID_NUMBER=$(UID_NUMBER)
	@echo GID_NUMBER=$(GID_NUMBER)
	@echo DOCKER_GID_NUMBER=$(DOCKER_GID_NUMBER)
