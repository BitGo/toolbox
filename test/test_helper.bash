#!/bin/bash

setup(){
	GNUPGHOME="$(mktemp -d -p /dev/shm/)"; export GNUPGHOME
	GPG_AGENT_INFO="${GNUPGHOME}/S.gpg-agent"; export GPG_AGENT_INFO
	SSH_AUTH_SOCK="${GNUPGHOME}/S.gpg-agent.ssh"; export SSH_AUTH_SOCK
	SCRIPT_REPO="git@toolbox-test:scripts.git"
	gpg-agent --homedir "${GNUPGHOME}" --disable-scdaemon --daemon \
		>/dev/null 2>&1

	git config --global user.name "Toolbox Test"
	git config --global user.email "toolbox-test@localhost"
}

teardown(){
	gpgconf --kill gpg-agent
	rm -rf "${GNUPGHOME}"
	unset GNUPGHOME GPG_AGENT_INFO SSH_AUTH_SOCK
	sudo rm -rf /git/
	#[ -f "/run/sshd.pid" ] && sudo kill "$(cat /run/sshd.pid)"
}

start_sshd(){
	sudo mkdir -p /git/.ssh
	sudo cp /home/admin/keys/ssh/git_ssh.pub  /git/.ssh/authorized_keys
	sudo git init --bare /git/scripts.git
	sudo chown -R git:git /git
	sudo /usr/sbin/sshd -e -p 22 >/dev/null 2>&1

	mkdir -p ~/.ssh
	ssh-keyscan toolbox-test > ~/.ssh/known_hosts
	sudo cp /home/admin/keys/ssh/git_ssh.prv  ~/.ssh/id_ed25519
	sudo chown -R admin:admin ~/.ssh
}

populate_scripts_repo(){
	script_dir=$(mktemp -d -p /dev/shm)
	git clone "${SCRIPT_REPO}" "${script_dir}"
	cat <<-EOF > "${script_dir}/hello"
		#!/bin/bash
		echo "hello"
	EOF
	chmod +x "${script_dir}/hello"
	cat <<-EOF > "${script_dir}/rush.rc"
		rule hello
		  command ^hello$
		  set[0] /home/user/repos/scripts/hello
	EOF
	git -C "${script_dir}" add .
	git -C "${script_dir}" commit -m "add hello script"
	git -C "${script_dir}" push origin master
}



enable_key(){
	name=${1?}
	gpg --import /home/admin/keys/pgp/"${name}".pub >/dev/null 2>&1
	gpg --import /home/admin/keys/pgp/"${name}".prv >/dev/null 2>&1
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
