FROM ubuntu:16.04
LABEL authors.maintainer "Grzegorz Bizon <grzegorz@gitlab.com>"
LABEL authors.contributor "Hrvoje Marjanovic <hrvoje.marjanovic@gmail.com>"

ENV DEBIAN_FRONTEND noninteractive

# install essentials

RUN apt-get update
RUN apt-get -y install curl wget git sudo build-essential \
                       software-properties-common \
                       python-software-properties

# rest of gitlab requirements
RUN apt-get install -y git postgresql postgresql-contrib libpq-dev \
                       redis-server libicu-dev cmake g++ libkrb5-dev libre2-dev \
                       ed pkg-config libsqlite3-dev libreadline-dev libssl-dev

# install nodejs
RUN curl -sL https://deb.nodesource.com/setup_6.x | bash -
RUN apt-get install -y nodejs

# GDK tools
RUN apt-get install -y net-tools psmisc apt-transport-https

# install yarn
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
RUN apt-get update && apt-get install -y yarn

# install Go
RUN wget -q https://storage.googleapis.com/golang/go1.8.3.linux-amd64.tar.gz
RUN tar -C /usr/local -xzf go1.8.3.linux-amd64.tar.gz
ENV PATH $PATH:/usr/local/go/bin

# Add GDK user
RUN useradd --user-group --create-home gdk

USER gdk

# Install rbenv
RUN git clone https://github.com/sstephenson/rbenv.git /home/gdk/.rbenv
RUN echo 'export PATH="/home/gdk/.rbenv/bin:$PATH"' >> /home/gdk/.bash_profile
RUN echo 'eval "$(rbenv init -)"' >> /home/gdk/.bash_profile

# install ruby-build
RUN mkdir /home/gdk/.rbenv/plugins
RUN git clone https://github.com/sstephenson/ruby-build.git /home/gdk/.rbenv/plugins/ruby-build
RUN bash -l -c "rbenv install 2.3.5 && rbenv global 2.3.5"
