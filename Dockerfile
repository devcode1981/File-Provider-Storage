FROM ubuntu:16.04 AS base
LABEL authors.maintainer "GDK contributors: https://gitlab.com/gitlab-org/gitlab-development-kit/graphs/master"

# Directions when writing this dockerfile:
# Keep least changed directives first. This improves layers caching when rebuilding.

RUN useradd --user-group --create-home gdk
COPY packages.txt /
RUN apt-get update && apt-get install -y $(sed -e 's/#.*//' /packages.txt)

# stages for fetching remote content
# highly cacheable
FROM alpine AS fetch
RUN apk add --no-cache coreutils curl tar git

FROM fetch AS source-rbenv
ARG RBENV_REVISION=59785f6762e9325982584cdab1a4c988ed062020
RUN git clone https://github.com/rbenv/rbenv && cd rbenv && git checkout $RBENV_REVISION

FROM fetch AS source-ruby-build
ARG RUBY_BUILD_REVISION=095d9db34fcbe24d38a16c9462cb853748bc65e7
RUN git clone https://github.com/rbenv/ruby-build && cd ruby-build && git checkout $RUBY_BUILD_REVISION

FROM fetch AS go
ARG GO_SHA256=4b677d698c65370afa33757b6954ade60347aaca310ea92a63ed717d7cb0c2ff
ARG GO_VERSION=1.10.2
RUN curl --silent --location --output go.tar.gz https://dl.google.com/go/go$GO_VERSION.linux-amd64.tar.gz
RUN echo "$GO_SHA256  go.tar.gz" | sha256sum -c -
RUN tar -C /usr/local -xzf go.tar.gz

FROM node:8-jessie AS nodejs
# contains nodejs and yarn in /usr/local
# https://github.com/nodejs/docker-node/blob/86b9618674b01fc5549f83696a90d5bc21f38af0/8/jessie/Dockerfile

FROM base AS rbenv
WORKDIR /home/gdk
RUN echo 'export PATH="/home/gdk/.rbenv/bin:$PATH"' >> .bash_profile
RUN echo 'eval "$(rbenv init -)"' >> .bash_profile
COPY --from=source-rbenv --chown=gdk /rbenv .rbenv
COPY --from=source-ruby-build --chown=gdk /ruby-build .rbenv/plugins/ruby-build
USER gdk
RUN bash -l -c "rbenv install 2.5.3 && rbenv global 2.5.3"

# build final image
FROM base AS release

WORKDIR /home/gdk
ENV PATH $PATH:/usr/local/go/bin

COPY --from=go /usr/local/ /usr/local/
COPY --from=nodejs /usr/local/ /usr/local/
COPY --from=rbenv --chown=gdk /home/gdk/ .

USER gdk
