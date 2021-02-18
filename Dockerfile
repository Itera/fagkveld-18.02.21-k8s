FROM ubuntu:20.04

EXPOSE 8091
EXPOSE 9898

ENV TZ=Europe/Oslo
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN apt-get -qq update && \
    apt-get -qq install -y ca-certificates curl apt-transport-https lsb-release gnupg software-properties-common git wget locales jq dnsutils

RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

RUN curl -sL https://packages.microsoft.com/keys/microsoft.asc | \
    gpg --dearmor | \
    tee /etc/apt/trusted.gpg.d/microsoft.gpg > /dev/null
RUN echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $(lsb_release -cs) main" | \
    tee /etc/apt/sources.list.d/azure-cli.list

RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
RUN apt-key fingerprint 0EBFCD88
RUN apt-add-repository -y \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"

RUN apt-get -qq update && \
    apt-get -qq install -y azure-cli=2.18.0-1~focal docker-ce-cli=5:20.10.3~3-0~ubuntu-focal

RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.18.9/bin/linux/amd64/kubectl && chmod +x ./kubectl && mv ./kubectl /usr/local/bin/kubectl
RUN wget -qqc https://github.com/derailed/k9s/releases/download/v0.22.1/k9s_Linux_x86_64.tar.gz -O - | tar -xz && chmod +x ./k9s && mv ./k9s /usr/local/bin/k9s
RUN wget -qqc https://get.helm.sh/helm-v3.4.1-linux-amd64.tar.gz -O - | tar -xz && chmod +x ./linux-amd64/helm && mv ./linux-amd64/helm /usr/local/bin/helm

RUN curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | bash -s 3.8.7 && cp /kustomize /usr/local/bin/

WORKDIR /code
