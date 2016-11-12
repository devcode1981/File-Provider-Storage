FROM ubuntu:16.04
MAINTAINER hrvoje.marjanovic@gmail.com

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
RUN apt-get -y install git postgresql postgresql-contrib libpq-dev redis-server libicu-dev cmake g++ nodejs libkrb5-dev golang ed pkg-config


# Install rbenv
RUN git clone https://github.com/sstephenson/rbenv.git /usr/local/rbenv
RUN echo '# rbenv setup' > /etc/profile.d/rbenv.sh
RUN echo 'export RBENV_ROOT=/usr/local/rbenv' >> /etc/profile.d/rbenv.sh
RUN echo 'export PATH="$RBENV_ROOT/bin:$PATH"' >> /etc/profile.d/rbenv.sh
RUN echo 'eval "$(rbenv init -)"' >> /etc/profile.d/rbenv.sh
RUN chmod +x /etc/profile.d/rbenv.sh

# install ruby-build
RUN mkdir /usr/local/rbenv/plugins
RUN git clone https://github.com/sstephenson/ruby-build.git /usr/local/rbenv/plugins/ruby-build

ENV RBENV_ROOT /usr/local/rbenv

ENV PATH $RBENV_ROOT/bin:$RBENV_ROOT/shims:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

RUN apt-get install -y libreadline-dev

RUN rbenv install 2.3.1
RUN rbenv global 2.3.1

RUN apt-get -y install npm sudo

RUN useradd gdk

RUN mkdir /home/gdk;  chown gdk /home/gdk
RUN chown -R gdk:gdk /usr/local/rbenv/
