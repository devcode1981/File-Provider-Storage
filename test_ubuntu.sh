#!/bin/bash

set -e

gem install gitlab-development-kit

gdk init
cd gitlab-development-kit
gdk install
support/set-gitlab-upstream

gdk run &

sleep 30

wget http://localhost:3000/

