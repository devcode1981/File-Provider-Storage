#!/bin/bash

set -ex

gem install gitlab-development-kit

cd /home/gdk
gdk init
cd gitlab-development-kit
gdk install
support/set-gitlab-upstream

gdk run &

sleep 10

curl http://127.0.0.1:3000/

