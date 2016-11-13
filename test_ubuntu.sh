#!/bin/bash

set -ex

ls -l
pwd
# sudo -i -H -u gdk bash -c 'gem install gitlab-development-kit'

cd /home/gdk
sudo -H -u gdk bash -l gdk init
cd gitlab-development-kit
sudo -H -u gdk bash -l gdk install
sudo -H -u gdk bash -l support/set-gitlab-upstream

sudo -H -u gdk bash -l gdk run &

sleep 10

curl http://127.0.0.1:3000/

