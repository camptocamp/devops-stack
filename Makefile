CLUSTER_NAME=$(shell git name-rev --name-only HEAD)
BASE_DOMAIN=127-0-0-1.nip.io

DOCKER_HOST="tcp://127.0.0.1:2376/"
UID_NUMBER=$(shell id -u $$USER)
GID_NUMBER=$(shell id -g $$USER)
DOCKER_GID_NUMBER=$(shell stat -c %g /var/run/docker.sock)
CI_PROJECT_URL="https://github.com/$(shell git config --get remote.origin.url | sed -Ene's#git@github.com:([^/]*)/(.*).git#\1/\2#p').git"

test: deploy
	docker run --rm -it \
		--user $(UID_NUMBER):$(GID_NUMBER) \
		-v $$PWD:/workdir \
		--network host \
		--env CLUSTER_NAME=$(CLUSTER_NAME) \
		--env BASE_DOMAIN=$(BASE_DOMAIN) \
		--env HOME=/tmp \
		--entrypoint "" \
		--workdir /workdir \
		curlimages/curl /workdir/scripts/test.sh

deploy: kubeconfig.yaml
	docker run --rm -it \
		--user $(UID_NUMBER):$(GID_NUMBER) \
		-v $$PWD:/workdir \
		-v $$PWD/kubeconfig.yaml:/tmp/.kube/config \
		--network host \
		--env HOME=/tmp \
		--env KUBECTL_COMMAND=apply \
		--env ARGOCD_OPTS="--plaintext --port-forward --port-forward-namespace argocd" \
		--entrypoint "" \
		--workdir /workdir \
		argoproj/argocd:v1.6.2 /workdir/scripts/deploy.sh

kubeconfig.yaml: terraform/*
	touch v $$HOME/.terraformrc
	docker run --rm -it \
		--group-add $(DOCKER_GID_NUMBER) \
		--user $(UID_NUMBER):$(GID_NUMBER) \
		-v /var/run/docker.sock:/var/run/docker.sock \
		-v $$PWD:/workdir \
		-v $$HOME/.terraformrc:/tmp/.terraformrc \
		-v $$HOME/.terraform.d:/tmp/.terraform.d \
		--env HOME=/tmp \
		--env TF_VAR_k3s_kubeconfig_dir=$$PWD \
		--env CI_PROJECT_URL=$(CI_PROJECT_URL) \
		--env CLUSTER_NAME=$(CLUSTER_NAME) \
		--entrypoint "" \
		--workdir /workdir \
		hashicorp/terraform:0.13.3 /workdir/scripts/provision.sh

clean:
	touch v $$HOME/.terraformrc
	docker run --rm -it \
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
	rm kubeconfig.yaml
	rm values.yaml
