#!/bin/bash

setup(){
	GNUPGHOME="$(mktemp -d -p /dev/shm/)"; export GNUPGHOME
	GPG_AGENT_INFO="${GNUPGHOME}/S.gpg-agent"; export GPG_AGENT_INFO
	SSH_AUTH_SOCK="${GNUPGHOME}/S.gpg-agent.ssh"; export SSH_AUTH_SOCK
	gpg-agent --homedir "${GNUPGHOME}" --disable-scdaemon --daemon \
		>/dev/null 2>&1
}

teardown(){
	gpgconf --kill gpg-agent
	rm -rf "${GNUPGHOME}"
	unset GNUPGHOME GPG_AGENT_INFO SSH_AUTH_SOCK
}

enable_key(){
	name=${1?}
	gpg --import /home/admin/keys/"${name}".pub >/dev/null 2>&1
	gpg --import /home/admin/keys/"${name}".prv >/dev/null 2>&1
	gpg --list-keys --fingerprint --with-colons \
	| sed -E -n -e 's/^fpr:::::::::([0-9A-F]+):$/\1:6:/p' \
	| gpg --import-ownertrust >/dev/null 2>&1
	gpg --with-keygrip --with-colons -k 2>/dev/null \
	| grep -A2 "::a::" \
	| sed -E -n -e 's/^grp:::::::::([0-9A-F]+):$/\1 0/p' \
	> "${GNUPGHOME}/sshcontrol"
}

ssh_command(){
	ssh \
		-p 2222 \
		-a \
		-o UserKnownHostsFile=/dev/null \
		-o StrictHostKeyChecking=no \
		-o LogLevel=ERROR \
		"$1"@"${CONTAINER}" \
		"$2"
}
