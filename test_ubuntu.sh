#!/bin/bash
gem install gitlab-development-kit

gdk init
cd gitlab-development-kit
gdk install
support/set-gitlab-upstream

