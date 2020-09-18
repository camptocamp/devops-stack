CLUSTER_NAME=blue
BASE_DOMAIN=127-0-0-1.nip.io

DOCKER_HOST="tcp://127.0.0.1:2376/"
UID_NUMBER=$(shell id -u $$USER)
GID_NUMBER=$(shell id -g $$USER)

test: deploy
	docker run --rm -it \
		-v $$PWD:/workdir \
		--env CLUSTER_NAME=$(CLUSTER_NAME) \
		--env BASE_DOMAIN=$(BASE_DOMAIN) \
		--entrypoint "" \
		--workdir /workdir \
		curlimages/curl /workdir/scripts/test.sh

deploy: kubeconfig.yaml
	docker run --rm -it \
		-v $$PWD:/workdir \
		-v $$PWD/kubeconfig.yaml:/home/argocd/.kube/config \
		--group-add $(GID_NUMBER) \
		--network host \
		--env KUBECTL_COMMAND=apply \
		--env ARGOCD_OPTS="--plaintext --port-forward --port-forward-namespace argocd" \
		--entrypoint "" \
		--workdir /workdir \
		argoproj/argocd:v1.7.5 /workdir/scripts/deploy.sh

kubeconfig.yaml:
	docker run --rm -it \
		--group-add $(shell stat -c %g /var/run/docker.sock) \
		--user $(UID_NUMBER):$(GID_NUMBER) \
		-v /var/run/docker.sock:/var/run/docker.sock \
		-v $$PWD:/workdir \
		-v $$HOME/.terraformrc:/tmp/.terraformrc \
		-v $$HOME/.terraform.d:/tmp/.terraform.d \
		--env HOME=/tmp \
		--env TF_VAR_k3s_kubeconfig_dir=$$PWD \
		--entrypoint "" \
		--workdir /workdir \
		hashicorp/terraform:0.13.3 /workdir/scripts/provision.sh

clean:
	docker run --rm -it \
		--group-add $(shell stat -c %g /var/run/docker.sock) \
		--user $(UID_NUMBER):$(GID_NUMBER) \
		-v /var/run/docker.sock:/var/run/docker.sock \
		-v $$PWD:/workdir \
		-v $$HOME/.terraformrc:/tmp/.terraformrc \
		-v $$HOME/.terraform.d:/tmp/.terraform.d \
		--env HOME=/tmp \
		--env TF_VAR_k3s_kubeconfig_dir=$$PWD \
		--entrypoint "" \
		--workdir /workdir \
		hashicorp/terraform:0.13.3 /workdir/scripts/destroy.sh
