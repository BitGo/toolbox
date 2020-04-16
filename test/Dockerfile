FROM debian:buster

RUN adduser admin && \
    apt-get clean && \
    apt-get update && \
    apt-get install -y --force-yes \
        bats \
        sudo \
        procps \
        gnupg \
        pinentry-tty \
        ssh \
        git &&\
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ADD . /home/admin/

RUN \
    useradd -m -d /git -s /usr/bin/git-shell git && \
    usermod -p '*' git && \
    mkdir -p /run/sshd && \
    chown root /run/sshd && \
    printf "source /home/admin/test_helper.bash\nsetup" \
        >> /home/admin/.bashrc && \
    chown admin:admin /home/admin && \
    echo '%admin ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

USER admin

WORKDIR /home/admin

ENV LANG=C.UTF-8 \
    TZ=UTC \
    TERM=xterm-256color \
    USER="admin" \
    HOME="/home/admin"

CMD ["/usr/bin/bats", "/test/test.bats"]
