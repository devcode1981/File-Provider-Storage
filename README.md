# GitLab Development Kit

Configure and manage a [GitLab](https://about.gitlab.com) development
environment.

Read on for installation instructions or skip to
[doc/howto](doc/howto/README.md) for usage documentation.

## Overview

GitLab Development Kit (GDK) provides a collection of scripts and
other resources to install and manage a GitLab installation for
development purposes. The source code of GitLab is spread over
multiple repositories and it requires Ruby, Go, Postgres/MySQL, Redis
and more to run. GDK helps you install and configure all these
different components, and start/stop them when you work on GitLab.

## Contributing to GitLab Development Kit

The source of GitLab Development Kit is [hosted on
GitLab.com](https://gitlab.com/gitlab-org/gitlab-development-kit/) and
contributions are welcome, per the [contribution
guidelines](https://gitlab.com/gitlab-org/gitlab-ce/blob/master/CONTRIBUTING.md) and
the contributor license agreements linked to from there.

## Getting started

To start using GDK follow these three steps:

- [Prepare your computer](doc/prepare.md)
- [Install GDK](doc/set-up-gdk.md)
- [Learn how to use GDK](doc/howto/README.md)

## Design goals

- Get the user started, do not try to take care of everything
- Run everything as your 'desktop' user on your development machine
- GitLab Development Kit itself does not run `sudo` commands
- It is OK to leave some things to the user (e.g. installing Ruby)

## Differences with production

- gitlab-workhorse does not serve static files
- C compiler needed to run `bundle install` (not needed with Omnibus)
- GitLab can rewrite its program code and configuration data (read-only with
  Omnibus)
- 'Assets' (Javascript/CSS files) are generated on the fly (pre-compiled at
  build time with Omnibus)
- Gems (libraries) for development and functional testing get installed and
  loaded
- No unified configuration management for GitLab and gitlab-shell
  (handled by Omnibus)
- No privilege separation between Ruby, Postgres and Redis
- No easy upgrades
- Need to download and compile new gems ('bundle install') on each upgrade
- etc.

## License

The GitLab Development Kit is distributed under the MIT license,
see the LICENSE file.
