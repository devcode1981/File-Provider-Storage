# CHANGELOG

This Changelog tracks major changes to the GitLab Development Kit, such as dependency updates (those not handled by Bundler) and new features.

## September 5, 2016
- Added a Changelog.

## August 16, 2016
- Updated PhantomJS to 2.1.1. !182

## August 11, 2016
- Updated Ruby to 2.3.1. !178

## August 8, 2016
- Added the [gitlab-development-kit gem][gdk-gem], commands can now be run using the `gdk` CLI. !174
- Began using a GOPATH for GitLab Workhorse, this change requires manual intervention. [See the update instructions here][workhorse-changes]. !173


[gdk-gem]: https://rubygems.org/gems/gitlab-development-kit
[workhorse-changes]: https://gitlab.com/gitlab-org/gitlab-development-kit/blob/fd04b7f1a3a72302af71c1a7923daaa5b22dcd28/gitlab-workhorse/README.md#cleaning-up-an-old-gitlab-workhorse-checkout
