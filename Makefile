DOCKER_HOST="tcp://127.0.0.1:2376/"
UID_NUMBER=$(shell id -u $$USER)
GID_NUMBER=$(shell id -g $$USER)
ARGOCD_OPTS="--plaintext --port-forward --port-forward-namespace argocd"

provision:
	docker run --rm -it \
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
		--network host \
		--entrypoint "" \
		--workdir /workdir \
		argoproj/argocd:v1.7.5 /workdir/scripts/deploy.sh

destroy:
	docker run --rm -it \
		-v /var/run/docker.sock:/var/run/docker.sock \
		-v $$PWD:/workdir \
		-v $$HOME/.terraformrc:/root/.terraformrc \
		-v $$HOME/.terraform.d:/root/.terraform.d \
		--entrypoint "" \
		--workdir /workdir \
		hashicorp/terraform:0.13.3 /workdir/scripts/destroy.sh
