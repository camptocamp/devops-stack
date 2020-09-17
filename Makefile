DOCKER_HOST="tcp://127.0.0.1:2376/"
UID_NUMBER=$(shell id -u $$USER)
GID_NUMBER=$(shell id -g $$USER)

provision:
	docker run --rm -it \
		-v /var/run/docker.sock:/var/run/docker.sock \
		-v $$PWD:/workdir \
		-v $$HOME/.terraformrc:/root/.terraformrc \
		-v $$HOME/.terraform.d:/root/.terraform.d \
		--entrypoint "" \
		--workdir /workdir \
		hashicorp/terraform:0.13.3 /workdir/scripts/provision.sh

destroy:
	docker run --rm -it \
		-v /var/run/docker.sock:/var/run/docker.sock \
		-v $$PWD:/workdir \
		-v $$HOME/.terraformrc:/root/.terraformrc \
		-v $$HOME/.terraform.d:/root/.terraform.d \
		--entrypoint "" \
		--workdir /workdir \
		hashicorp/terraform:0.13.3 /workdir/scripts/destroy.sh
