## Primary Targets

.PHONY: build
build:
	docker build -t local/toolbox .

.PHONY: start
start: build
	docker network inspect toolbox || docker create network toolbox
	docker inspect -f '{{.State.Running}}' toolbox 2>/dev/null || \
	docker run \
		--rm \
		--hostname=toolbox \
		--detach=true \
		--name toolbox \
		--env-file="test/test.env" \
		--volume=${CURDIR}/test/keys:/etc/keys \
		--network=toolbox \
		--expose="2222" \
		local/toolbox

.PHONY: stop
stop:
	docker rm -f toolbox

.PHONY: ssh
ssh: start
	while sleep 1; do ssh -p 2222 admin@localhost; done

.PHONY: shell
shell: start
	docker exec -it --user=root toolbox bash

.PHONY: logs
logs:
	docker logs toolbox

.PHONY: test
test: start build-test
	docker run \
		--rm \
		--hostname=toolbox-test \
		--name toolbox-test \
		--network=toolbox \
		--env="CONTAINER=toolbox" \
		local/toolbox-test

.PHONY: test-shell
test-shell: start build-test
	docker run \
		--rm \
		-it \
		--hostname=toolbox-test \
		--name toolbox-test \
		--network=toolbox \
		--env CONTAINER="toolbox" \
		local/toolbox-test \
		bash

update-packages: start
	docker exec -it --user=root toolbox update-packages
	docker cp toolbox:/etc/apt/packages.list ${CURDIR}/packages.list

## Internal targets

.PHONY: build-test
build-test:
	docker build -t local/toolbox-test test/
