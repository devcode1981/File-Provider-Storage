FROM ubuntu:16.04
LABEL authors.maintainer "Grzegorz Bizon <grzegorz@gitlab.com>"
LABEL authors.contributor "Hrvoje Marjanovic <hrvoje.marjanovic@gmail.com>"

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update
RUN apt-get -y install curl git-core software-properties-common python-software-properties

# This PPA contains an up-to-date version of Go
RUN apt-add-repository -y ppa:ubuntu-lxc/lxd-stable
RUN apt-get update

# install essentials
RUN apt-get -y install build-essential
RUN apt-get install -y -q git
RUN apt-get install -y libssl-dev

# rest of gitlab requirements
RUN apt-get install -y git postgresql postgresql-contrib libpq-dev redis-server \
  libicu-dev cmake g++ nodejs libkrb5-dev golang ed pkg-config libsqlite3-dev \
  libreadline-dev npm sudo

# Install rbenv

RUN adduser --disabled-password --gecos "" gdk

USER gdk
RUN git clone https://github.com/sstephenson/rbenv.git /home/gdk/.rbenv
RUN echo 'export PATH="/home/gdk/.rbenv/bin:$PATH"' >> /home/gdk/.bash_profile
RUN echo 'eval "$(rbenv init -)"' >> /home/gdk/.bash_profile

# install ruby-build
RUN mkdir /home/gdk/.rbenv/plugins
RUN git clone https://github.com/sstephenson/ruby-build.git /home/gdk/.rbenv/plugins/ruby-build
RUN bash -l -c "rbenv install 2.3.3 && rbenv global 2.3.3"
