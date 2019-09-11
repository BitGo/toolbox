ARG GOLANG_IMAGE_REF=sha256:84349ee862d8bafff35e0d2bfd539da565b536b4dfce654773fc21a1db2da6d7
ARG ALPINE_IMAGE_REF=sha256:484dfd8f6ffc7237d4d91cb107dad73f4594c33eacfd0fe77c284e36bad9303d

FROM golang@${GOLANG_IMAGE_REF} as golang
ARG FIXUID_GIT_REF="0ec93d22e52bde5b7326e84cb62fd26a3d20cead"
ARG TOML_GIT_REF="3012a1dbe2e4bd1391d42b32f0577cb7bbc7f005"
ARG OZZOCONFIG_GIT_REF="0ff174cf5aa6480026e0b40c14fd9cfb61c4abf6"
ARG YAMLV2_GIT_REF="51d6538a90f86fe93ac480b35f37b2be17fef232"
ARG JSONPREPROCESS_GIT_REF="a4e954386171be645f1eb7c41865d2624b69259d"
ARG GLIDE_GIT_REF="b94b39d657d8abcccba6545e148f1201aee6ffec"
ARG KUBERNETES_GIT_REF="e298fc723f2597697b770f88ce47fe93507f7463"
ARG HELM_GIT_REF="e70f012bb6b7b4aa19aa7190d68e182cb1f5b9cb"
ARG TERRAFORM_GIT_REF="4ebf9082cde695a4bbc908cbf373a2c8139fe534"
ARG TERRAFORM_HELM_GIT_REF="a8e657341b68c09f901736974aee3aeccdd38be9"
ARG TERRAFORM_KUBERNETES_GIT_REF="56bb8e012f5f4bdd2fb906e1e6a567e3e57b46a4"

RUN apk add bash git make

RUN printf "\
github.com/Masterminds/glide github.com/Masterminds/glide ${GLIDE_GIT_REF} \n\
github.com/kubernetes/kubernetes k8s.io/kubernetes ${KUBERNETES_GIT_REF} \n\
github.com/helm/helm k8s.io/helm ${HELM_GIT_REF} \n\
github.com/hashicorp/terraform github.com/hashicorp/terraform ${TERRAFORM_GIT_REF} \n\
github.com/terraform-providers/terraform-provider-helm github.com/terraform-providers/terraform-provider-helm ${TERRAFORM_HELM_GIT_REF} \n\
github.com/terraform-providers/terraform-provider-kubernetes github.com/terraform-providers/terraform-provider-kubernetes ${TERRAFORM_KUBERNETES_GIT_REF}\n" \
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

RUN go build -o /usr/local/bin/glide github.com/Masterminds/glide
RUN go build -o /usr/local/bin/kubectl k8s.io/kubernetes/cmd/kubectl
RUN cd /go/src/k8s.io/helm \
    && make bootstrap build \
    && cp bin/helm /usr/local/bin/ \
    && cp bin/tiller /usr/local/bin/
RUN go build -o /usr/local/bin/terraform github.com/hashicorp/terraform
RUN go build -o /usr/local/bin/terraform-provider-kubernetes \
    github.com/terraform-providers/terraform-provider-kubernetes
RUN go build -o /usr/local/bin/terraform-provider-helm \
    github.com/terraform-providers/terraform-provider-helm

FROM alpine@${ALPINE_IMAGE_REF}

COPY --from=golang /usr/local/bin/terraform /usr/local/bin/
COPY --from=golang /usr/local/bin/terraform-provider-kubernetes \
    /usr/local/bin/terraform-provider-kubernetes
COPY --from=golang /usr/local/bin/terraform-provider-helm \
    /usr/local/bin/terraform-provider-helm
COPY --from=golang /usr/local/bin/kubectl /usr/local/bin/
COPY --from=golang /usr/local/bin/helm /usr/local/bin/
COPY --from=golang /usr/local/bin/tiller /usr/local/bin/
COPY --from=golang /usr/local/bin/fixuid /usr/local/bin/

ENV LANG=C.UTF-8 \
    TZ=UTC \
    TERM=xterm-256color \
    AUTHORIZED_KEYS="" \
    USER="admin"

STOPSIGNAL SIGCONT

RUN \
  apk add --no-cache \
    runit \
    shadow \
    openssh \
    rsync \
    bash \
    aws-cli \
    tzdata \
    tmux \
  && echo "toolbox" > /etc/hostname \
  && rm -rf /tmp/* /var/cache/apk/* /etc/motd

ADD etc/ /etc/
ADD var/ /var/
ADD bin/ /bin/

EXPOSE 22

CMD ["/sbin/runit-init"]
