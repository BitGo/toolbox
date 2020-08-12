ARG GOLANG_IMAGE_REF=sha256:36c384d8593f8989b7a50bebf9569c9f6a43a6881baa8a248a84251d2ca17ddb
ARG DEBIAN_IMAGE_REF=sha256:9d2b250af5748cf8fb2c7e9a14aab830c251daa3f8f3bc787bd4a3e8c586f39a

FROM golang:1.13.2-buster@${GOLANG_IMAGE_REF} as golang
ARG FIXUID_GIT_REF="0ec93d22e52bde5b7326e84cb62fd26a3d20cead"
ARG TOML_GIT_REF="3012a1dbe2e4bd1391d42b32f0577cb7bbc7f005"
ARG OZZOCONFIG_GIT_REF="0ff174cf5aa6480026e0b40c14fd9cfb61c4abf6"
ARG YAMLV2_GIT_REF="51d6538a90f86fe93ac480b35f37b2be17fef232"
ARG JSONPREPROCESS_GIT_REF="a4e954386171be645f1eb7c41865d2624b69259d"
ARG GLIDE_GIT_REF="b94b39d657d8abcccba6545e148f1201aee6ffec"
ARG KUBERNETES_GIT_REF="e298fc723f2597697b770f88ce47fe93507f7463"
ARG HELM_GIT_REF="8dce272473e5f2a7bf58ce79bb5c3691db54c96b"
ARG TERRAFORM_GIT_REF="4ebf9082cde695a4bbc908cbf373a2c8139fe534"
ARG TERRAFORM_HELM_GIT_REF="0ae76f659dcfdc88c0fa70370b0fe1e126177226"
ARG TERRAFORM_KUBERNETES_GIT_REF="fc2b788bafc2f52ac60ef5704d152ef12871537b"
ARG KOPS_GIT_REF="d5078612f641d89190edb39f3fedcee2548ba68f"
ARG VELERO_GIT_REF="5d008491bbf681658d3e372da1a9d3a21ca4c03c"
ARG SOPS_GIT_REF="647560046fef85d8ba1800ed63528a364538391f"

RUN apt update && apt install -y bash git make

RUN printf "\
github.com/Masterminds/glide github.com/Masterminds/glide ${GLIDE_GIT_REF} \n\
github.com/kubernetes/kubernetes k8s.io/kubernetes ${KUBERNETES_GIT_REF} \n\
github.com/helm/helm k8s.io/helm ${HELM_GIT_REF} \n\
github.com/kubernetes/kops  k8s.io/kops ${KOPS_GIT_REF} \n\
github.com/vmware-tanzu/velero github.com/vmware-tanzu/velero ${VELERO_GIT_REF} \n\
github.com/hashicorp/terraform github.com/hashicorp/terraform ${TERRAFORM_GIT_REF} \n\
github.com/terraform-providers/terraform-provider-helm github.com/terraform-providers/terraform-provider-helm ${TERRAFORM_HELM_GIT_REF} \n\
github.com/terraform-providers/terraform-provider-kubernetes github.com/terraform-providers/terraform-provider-kubernetes ${TERRAFORM_KUBERNETES_GIT_REF} \n\
github.com/mozilla/sops go.mozilla.org/sops/v3 ${SOPS_GIT_REF}\n" \
> /go/src/repos

RUN echo ' \
    cat /go/src/repos | while read -r line; do \
        repo=$(echo $line | awk "{ print \$1 }"); \
        folder=$(echo $line | awk "{ print \$2 }"); \
        ref=$(echo $line | awk "{ print \$3 }"); \
        git clone "https://${repo}" "/go/src/${folder}"; \
        git -C "/go/src/${folder}" checkout ${ref};  \
    done' \
| bash

RUN cd /go/src/k8s.io/kops \
    && make \
    && echo "gopath: $GOPATH" \
    && cp -v /go/bin/kops /usr/local/bin/
RUN go build -o /usr/local/bin/glide github.com/Masterminds/glide
RUN go build -o /usr/local/bin/kubectl k8s.io/kubernetes/cmd/kubectl
RUN go build -o /usr/local/bin/terraform github.com/hashicorp/terraform
RUN cd /go/src/k8s.io/helm \
    && go get vbom.ml/util \
    && make bootstrap build \
    && cp bin/helm /usr/local/bin/ \
    && cp bin/tiller /usr/local/bin/
RUN go build -o /usr/local/bin/terraform-provider-kubernetes \
    github.com/terraform-providers/terraform-provider-kubernetes
RUN go build -o /usr/local/bin/terraform-provider-helm \
    github.com/terraform-providers/terraform-provider-helm
RUN go build -o /usr/local/bin/velero \
    github.com/vmware-tanzu/velero/cmd/velero
RUN cd /go/src/go.mozilla.org/sops/v3 \
    && make install \
    && cp -v /go/bin/sops /usr/local/bin/

FROM debian:buster@${DEBIAN_IMAGE_REF}
ARG AWS_CLI_GIT_BRANCH="1.16.242"
ARG AWS_CLI_GIT_REF="a031cf1ea60e6a810a5f2127f2c1ea13c39f549d"

COPY --from=golang /usr/local/bin/terraform /usr/local/bin/
COPY --from=golang /usr/local/bin/terraform-provider-kubernetes \
    /usr/local/bin/terraform-provider-kubernetes
COPY --from=golang /usr/local/bin/terraform-provider-helm \
    /usr/local/bin/terraform-provider-helm
COPY --from=golang /usr/local/bin/kubectl /usr/local/bin/
COPY --from=golang /usr/local/bin/helm /usr/local/bin/
COPY --from=golang /usr/local/bin/tiller /usr/local/bin/
COPY --from=golang /usr/local/bin/kops /usr/local/bin/
COPY --from=golang /usr/local/bin/velero /usr/local/bin/
COPY --from=golang /usr/local/bin/sops /usr/local/bin/

ENV LANG=C.UTF-8 \
    TZ=UTC \
    TERM=xterm-256color \
    AUTHORIZED_KEYS="" \
    USER="admin" \
    HOME="/home/admin"

STOPSIGNAL SIGCONT
RUN \
  adduser admin \
  && apt update \
  && apt install -y \
    bash \
    git \
    gnupg \
    groff \
    python3 \
    python3-pip \
    rsync \
    runit \
    runit-init \
    ssh \
    tmux \
    tzdata \
    vim \
    curl \
    dnsutils \
  && git clone --depth 1 --branch ${AWS_CLI_GIT_BRANCH} https://github.com/aws/aws-cli.git /tmp/aws-cli \
  && git -C /tmp/aws-cli checkout ${AWS_CLI_GIT_REF} \
  && cd /tmp/aws-cli \
  && printf "\
botocore==1.12.232 --hash=sha256:a57a8fd0145c68e31bb4baab549b27a12f6695068c8dd5f2901d8dc06572dbeb\n\
colorama==0.3.9 --hash=sha256:463f8483208e921368c9f306094eb6f725c6ca42b0f97e313cb5d5512459feda\n\
docutils==0.15.2 --hash=sha256:6c4f696463b79f1fb8ba0c594b63840ebd41f059e92b31957c46b74a4599b6d0\n\
jmespath==0.9.4 --hash=sha256:3720a4b1bd659dd2eecad0666459b9788813e032b83e7ba58578e48254e0a0e6\n\
pyasn1==0.4.7 --hash=sha256:62cdade8b5530f0b185e09855dd422bc05c0bbff6b72ff61381c09dac7befd8c\n\
python-dateutil==2.8.0 --hash=sha256:7e6584c74aeed623791615e26efd690f29817a27c73085b78e4bad02493df2fb\n\
PyYAML==5.1.2 --hash=sha256:01adf0b6c6f61bd11af6e10ca52b7d4057dd0be0343eb9283c878cf3af56aee4\n\
rsa==3.4.2 --hash=sha256:43f682fea81c452c98d09fc316aae12de6d30c4b5c84226642cf8f8fd1c93abd\n\
s3transfer==0.2.1 --hash=sha256:b780f2411b824cb541dbcd2c713d0cb61c7d1bcadae204cdddda2b35cef493ba\n\
six==1.12.0 --hash=sha256:3350809f0555b11f552448330d0b52d5f24c91a322ea4a15ef22629740f3761c\n\
urllib3==1.25.5 --hash=sha256:9c6c593cb28f52075016307fc26b0a0f8e82bc7d1ff19aaaa959b91710a56c47\n" \
     > requirements.txt \
  && pip3 install --require-hashes -r requirements.txt \
  && python3 setup.py install \
  && cd / \
  && echo "toolbox" > /etc/hostname \
  && rm -rf /tmp/* /var/cache/apk/* /etc/motd \
  && mkdir /run/sshd

ARG AUTHORIZED_KEYS=""

ADD etc/ /etc/
ADD var/ /var/
ADD bin/ /bin/

RUN echo "${AUTHORIZED_KEYS} > /etc/sshd/authorized_keys"

WORKDIR /home/admin
EXPOSE 22

CMD ["/sbin/runit"]
