#!/bin/bash

set -e

apt-get -y install npm sudo

useradd gdk

mkdir /home/gdk;  chown gdk /home/gdk
chown -R gdk:gdk /usr/local/rbenv/

sudo -H -u gdk bash -l gem install gitlab-development-kit

cd /home/gdk
sudo -H -u gdk bash -l gdk init
cd gitlab-development-kit
sudo -H -u gdk bash -l gdk install
sudo -H -u gdk bash -l support/set-gitlab-upstream

sudo -H -u gdk bash -l gdk run &

sleep 30

wget http://localhost:3000/

