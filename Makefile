.PHONY: build
build:
	docker build -t local/toolbox .

.PHONY: start
start: build
	docker inspect -f '{{.State.Running}}' toolbox 2>/dev/null || \
	docker run \
		--rm \
		--hostname=toolbox \
		--detach=true \
		--name toolbox \
		--env-file="test/test.env" \
		--volume=${CURDIR}/test/keys:/home/admin/keys \
		--publish=2222:22 \
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
