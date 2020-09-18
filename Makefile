DOCKER_HOST="tcp://127.0.0.1:2376/"
UID_NUMBER=$(shell id -u $$USER)
GID_NUMBER=$(shell id -g $$USER)
ARGOCD_OPTS="--plaintext --port-forward --port-forward-namespace argocd"
KUBECTL_COMMAND=apply

provision:
	docker run --rm -it \
		--group-add $(shell stat -c %g /var/run/docker.sock) \
		--user $(UID_NUMBER):$(GID_NUMBER) \
		-v /var/run/docker.sock:/var/run/docker.sock \
		-v $$PWD:/workdir \
		-v $$HOME/.terraformrc:/root/.terraformrc \
		-v $$HOME/.terraform.d:/root/.terraform.d \
		--entrypoint "" \
		--workdir /workdir \
		hashicorp/terraform:0.13.3 /workdir/scripts/provision.sh

deploy: provision
	docker run --rm -it \
		-v $$PWD:/workdir \
		-v /tmp/foo/kubeconfig.yaml:/home/argocd/.kube/config \
		--group-add $(GID_NUMBER) \
		--network host \
		--entrypoint "" \
		--workdir /workdir \
		argoproj/argocd:v1.7.5 /workdir/scripts/deploy.sh

clean:
	docker run --rm -it \
		--group-add $(shell stat -c %g /var/run/docker.sock) \
		--user $(UID_NUMBER):$(GID_NUMBER) \
		-v /var/run/docker.sock:/var/run/docker.sock \
		-v $$PWD:/workdir \
		-v $$HOME/.terraformrc:/root/.terraformrc \
		-v $$HOME/.terraform.d:/root/.terraform.d \
		--entrypoint "" \
		--workdir /workdir \
		hashicorp/terraform:0.13.3 /workdir/scripts/destroy.sh
