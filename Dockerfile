FROM ubuntu:18.04 AS base
LABEL authors.maintainer "GDK contributors: https://gitlab.com/gitlab-org/gitlab-development-kit/graphs/master"

# Directions when writing this dockerfile:
# Keep least changed directives first. This improves layers caching when rebuilding.

RUN useradd --user-group --create-home gdk
ENV DEBIAN_FRONTEND=noninteractive
COPY packages.txt /
RUN apt-get update && apt-get install -y software-properties-common \
    && add-apt-repository ppa:git-core/ppa -y \
    && apt-get install -y $(sed -e 's/#.*//' /packages.txt)

# stages for fetching remote content
# highly cacheable
FROM alpine AS fetch
RUN apk add --no-cache coreutils curl tar git

FROM fetch AS source-rbenv
ARG RBENV_REVISION=v1.1.1
RUN git clone --branch $RBENV_REVISION --depth 1 https://github.com/rbenv/rbenv

FROM fetch AS source-ruby-build
ARG RUBY_BUILD_REVISION=v20190423
RUN git clone --branch $RUBY_BUILD_REVISION --depth 1 https://github.com/rbenv/ruby-build

FROM fetch AS go
ARG GO_SHA256=aea86e3c73495f205929cfebba0d63f1382c8ac59be081b6351681415f4063cf
ARG GO_VERSION=1.12.5
RUN curl --silent --location --output go.tar.gz https://dl.google.com/go/go$GO_VERSION.linux-amd64.tar.gz
RUN echo "$GO_SHA256  go.tar.gz" | sha256sum -c -
RUN tar -C /usr/local -xzf go.tar.gz

FROM node:12-stretch AS nodejs
# contains nodejs and yarn in /usr/local
# https://github.com/nodejs/docker-node/blob/77f1baaa55acc71c9eda1866f0c162b434a63be5/10/jessie/Dockerfile
WORKDIR /stage
RUN install -d usr opt
RUN cp -al /usr/local usr
RUN cp -al /opt/yarn* opt

FROM base AS rbenv
WORKDIR /home/gdk
RUN echo 'export PATH="/home/gdk/.rbenv/bin:$PATH"' >> .bash_profile
RUN echo 'eval "$(rbenv init -)"' >> .bash_profile
COPY --from=source-rbenv --chown=gdk /rbenv .rbenv
COPY --from=source-ruby-build --chown=gdk /ruby-build .rbenv/plugins/ruby-build
USER gdk
RUN bash -l -c "rbenv install 2.6.3 && rbenv global 2.6.3"

# build final image
FROM base AS release

WORKDIR /home/gdk
ENV PATH $PATH:/usr/local/go/bin

COPY --from=go /usr/local/ /usr/local/
COPY --from=nodejs /stage/ /
COPY --from=rbenv --chown=gdk /home/gdk/ .

USER gdk

# simple tests that tools work
RUN ["bash", "-lec", "yarn --version; node --version; rbenv --version" ]
