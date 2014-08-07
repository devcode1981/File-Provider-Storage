# GitLab Development Kit

Run a GitLab development environment isolated in a directory.

This project uses Foreman to run dedicated Postgres and Redis processes for
GitLab development. All data is stored inside the gitlab-development-kit
directory. All connections to supporting services go through Unix domain
sockets to avoid port conflicts.

Note: at this time Redis still uses port 6379 because that is hard-wired into
the GitLab development and test environments.

## Design goals

- Get the user started, do not try to take care of everything
- Run everything as your 'desktop' user on your development machine
- GitLab Development Kit itself does not run `sudo` commands
- It is OK to leave some things to the user (e.g. installing Ruby)

## Installation

### Requirements

#### OS X 10.9

Install Ruby 2.1 and Bundler with your method of choice (RVM, ruby-build, rbenv, chruby, etc.).

```
brew install redis postgresql phantomjs
```

#### Debian

TODO

#### RedHat

TODO

### Repositories and gems

The Makefile will clone the repositories, install the Gem bundles and set up
basic configuration files.

```
# Clone the official repositories of gitlab and gitlab-shell
make
```

Alternatively, you can clone straight from your forked repositories.

```
# Clone your own forked repositories
make gitlab_repo=git@gitlab.com:example/gitlab-ce.git gitlab_shell_repo=git@gitlab.com:example/gitlab-shell.git
```

### Database initialization for development

```
cd gitlab
bundle exec rake db:create gitlab:setup
```

## Development

When doing development, you will need one shell session (terminal window)
running Postgres and Redis, and one or more other sessions to work on GitLab
itself.

### Example

First start Postgres and Redis.

```
# terminal window 1
# current directory: gitlab-development-kit
bundle exec foreman start
```

Next, start a Rails development server.

```
# terminal window 2
# current directory: gitlab-development-kit/gitlab
bundle exec foreman start
```

Now you can go to http://localhost:3000 in your browser.
