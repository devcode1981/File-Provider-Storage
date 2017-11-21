# CHANGELOG

This Changelog tracks major changes to the GitLab Development Kit,
such as dependency updates (those not handled by Bundler) and new
features.

## 2017-11-21

- [GitLab GEO] Add replication slot

## 2017-02-01

- Add webpack process to Procfile configure it within gitlab.yml !237
  Make sure to [update GDK](doc/update-gdk.md) and read the
  [troubleshooting section](doc/howto/troubleshooting.md#webpack).

## 2016-10-31

- Add root check to catch root move problems. Requires gem 0.2.3 or
  newer. Next time you run `git pull` in the gitlab-development-kit
  root directory, also run `gem install gitlab-development-kit` to
  upgrade the gem.

## 2016-09-09
- Update Procfile for gitlab_workhorse_secret

## 2016-09-05
- Added a Changelog.

## 2016-08-16
- Updated PhantomJS to 2.1.1. !182

## 2016-08-11
- Updated Ruby to 2.3.1. !178

## 2016-08-08
- Added the [gitlab-development-kit gem][gdk-gem], commands can now be run using the `gdk` CLI. !174
- Began using a GOPATH for GitLab Workhorse, this change requires manual intervention. [See the update instructions here][workhorse-changes]. !173


[gdk-gem]: https://rubygems.org/gems/gitlab-development-kit
[workhorse-changes]: https://gitlab.com/gitlab-org/gitlab-development-kit/blob/fd04b7f1a3a72302af71c1a7923daaa5b22dcd28/gitlab-workhorse/README.md#cleaning-up-an-old-gitlab-workhorse-checkout
