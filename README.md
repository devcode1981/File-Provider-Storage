# GitLab Development Kit

The GDK runs a GitLab development environment isolated in a directory.
This project uses Foreman to run dedicated Postgres and Redis processes for
GitLab development. All data is stored inside the gitlab-development-kit
directory. All connections to supporting services go through Unix domain
sockets to avoid port conflicts.

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [Design goals](#design-goals)
- [Differences with production](#differences-with-production)
- [GDK Setup](#gdk-setup)
  - [Clone GitLab Development Kit repository](#clone-gitlab-development-kit-repository)
  - [Native installation setup](#native-installation-setup)
    - [Prerequisites for all platforms](#prerequisites-for-all-platforms)
    - [OS X 10.9 (Mavericks), 10.10 (Yosemite), 10.11 (El Capitan)](#os-x-109-mavericks-1010-yosemite-1011-el-capitan)
    - [Ubuntu](#ubuntu)
    - [Arch Linux](#arch-linux)
    - [Debian](#debian)
    - [Fedora](#fedora)
    - [CentOS](#centos)
    - [Other platforms](#other-platforms)
- [Installation](#installation)
  - [GitLab Enterprise Edition](#gitlab-enterprise-edition)
- [Post-installation](#post-installation)
- [Development](#development)
  - [Example](#example)
  - [Running the tests](#running-the-tests)
  - [Simulating Broken Storage Devices](#simulating-broken-storage-devices)
  - [Simulating Slow Filesystems](#simulating-slow-filesystems)
- [Update gitlab and gitlab-shell repositories](#update-gitlab-and-gitlab-shell-repositories)
- [Update configuration files created by gitlab-development-kit](#update-configuration-files-created-by-gitlab-development-kit)
- [MySQL](#mysql)
- [PostgreSQL replication](#postgresql-replication)
- [OpenLDAP](#openldap)
- [Elasticsearch](#elasticsearch)
  - [Installation: OS X](#installation-os-x)
  - [Setup](#setup)
- [NFS](#nfs)
  - [Ubuntu / Debian](#ubuntu--debian)
- [HTTPS](#https)
- [SSH](#ssh)
- [Troubleshooting](#troubleshooting)
  - [Rebuilding gems with native extensions](#rebuilding-gems-with-native-extensions)
  - [Error in database migrations when pg_trgm extension is missing](#error-in-database-migrations-when-pg_trgm-extension-is-missing)
  - [Upgrading PostgreSQL](#upgrading-postgresql)
  - [Rails cannot connect to Postgres](#rails-cannot-connect-to-postgres)
  - [undefined symbol: SSLv2_method](#undefined-symbol-sslv2_method)
  - [Fix conflicts in database migrations if you use the same db for CE and EE](#fix-conflicts-in-database-migrations-if-you-use-the-same-db-for-ce-and-ee)
  - ['LoadError: dlopen' when starting Ruby apps](#loaderror-dlopen-when-starting-ruby-apps)
  - ['bundle install' fails due to permission problems](#bundle-install-fails-due-to-permission-problems)
  - ['bundle install' fails while compiling eventmachine gem](#bundle-install-fails-while-compiling-eventmachine-gem)
  - ['Invalid reference name' when creating a new tag](#invalid-reference-name-when-creating-a-new-tag)
  - [Other problems](#other-problems)
- [Executables](#executables)
  - [mount-slow-fs](#mount-slow-fs)
- [License](#license)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

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

## Development

When doing development, you will need one shell session (terminal window)
running Postgres and Redis, and one or more other sessions to work on GitLab
itself.

### Example

First start Postgres and Redis.

```
# current directory: gitlab-development-kit
./run
```

Now you can go to http://localhost:3000 in your browser.
The development login credentials are `root` and `5iveL!fe`

### Running the tests

In order to run the test you can use the following commands:
- `rake spinach` to run the spinach suite
- `rake spec` to run the rspec suite
- `rake teaspoon` to run the teaspoon test suite
- `rake gitlab:test` to run all the tests

Note: Both `rake spinach` and `rake spec` takes significant time to pass. 
Instead of running full test suite locally you can save a lot of time by running
a single test or directory related to your changes. After you submit merge request 
CI will run full test suite for you. Green CI status in the merge request means 
full test suite is passed.  

Note: You can't run `rspec .` since this will try to run all the `_spec.rb`
files it can find, also the ones in `/tmp`

To run a single test file you can use:

- `bundle exec rspec spec/controllers/commit_controller_spec.rb` for a rspec test
- `bundle exec spinach features/project/issues/milestones.feature` for a spinach test

To run several tests inside one directory:

- `bundle exec rspec spec/requests/api/` for the rspec tests if you want to test API only
- `bundle exec spinach features/profile/` for the spinach tests if you want to test only profile pages

If you want to use [Spring](https://github.com/rails/spring) set
`ENABLE_SPRING=1` in your environment.

### Simulating Broken Storage Devices

To test how GitLab behaves when the underlying storage system is not working
you can simply change your local GitLab instance to use an empty directory for
the repositories. To do so edit your `config/gitlab.yml` configuration file so
that the `gitlab_shell.repos_path` option for your environment (e.g.
"development") points to an empty directory.

### Simulating Slow Filesystems

To simulate a slow filesystem you can use the script `bin/mount-flow-fs`. This
script can be used to mount a local directory via SSHFS and slow down access to
the files in this directory. For more information see
[mount-slow-fs](#mount-slow-fs).

## Update gitlab and gitlab-shell repositories

When working on a new feature, always check that your `gitlab` repository is up
to date with the upstream master branch.

In order to fetch the latest code, first make sure that `foreman` for
postgres is runnning (needed for db migration) and then run:

```
make update
```

This will update both `gitlab` and `gitlab-shell` and run any possible
migrations. You can also update them separately by running `make gitlab-update`
and `make gitlab-shell-update` respectively.

If there are changes in the aformentioned local repositories or/and a different
branch than master is checked out, the `make update` commands will stash any
uncommitted changes and change to master branch prior to updating the remote
repositories.

## Update configuration files created by gitlab-development-kit

Sometimes there are changes in gitlab-development-kit that require
you to regenerate configuration files with `make`. You can always
remove an individual file (e.g. `rm Procfile`) and rebuild it by
running `make`. If you want to rebuild _all_ configuration files
created by the Makefile, run `make clean-config all`.

## MySQL

See [doc/mysql.md](doc/mysql.md).

## PostgreSQL replication

For Gitlab Geo, you will need a master/slave database replication defined.
There are a few extra steps to follow:

You must start with a clean postgres setup, (jump to next if you are installing
everything from scratch):

```
rm -rf postgresql
make postgresql
```

Initialize a slave database and setup replication:

```
# terminal window 1:
make postgresql-replication/cluster
foreman start postgresql

# terminal window 2:
make postgresql-replication/role
make postgresql-replication/backup

# go back to terminal window 1 and stop foreman by hitting "CTRL-C"
```

Follow [Post-installation](#post-installation) instructions.

## OpenLDAP

To run the OpenLDAP installation included in the GitLab development kit do the following:

```
vim Procfile # remove the comment on the OpenLDAP line
cd gitlab-openldap
make # will setup the databases
```

in the gitlab repository edit config/gitlab.yml;

```yaml
ldap:
  enabled: true
  servers:
    main:
      label: LDAP
      host: 127.0.0.1
      port: 3890
      uid: 'uid'
      method: 'plain' # "tls" or "ssl" or "plain"
      base: 'dc=example,dc=com'
      user_filter: ''
      group_base: 'ou=groups,dc=example,dc=com'
      admin_group: ''
    # Alternative server, multiple LDAP servers only work with GitLab-EE
    # alt:
    #   label: LDAP-alt
    #   host: 127.0.0.1
    #   port: 3890
    #   uid: 'uid'
    #   method: 'plain' # "tls" or "ssl" or "plain"
    #   base: 'dc=example-alt,dc=com'
    #   user_filter: ''
    #   group_base: 'ou=groups,dc=example-alt,dc=com'
    #   admin_group: ''
```

The second database is optional, and will only work with Gitlab-EE.

The following users are added to the LDAP server:

| uid      | Password | DN                                          | Last     |
| -------- | -------- | -------                                     | ----     |
| john     | password | `uid=john,ou=people,dc=example,dc=com`      |          |
| john0    | password | `uid=john0,ou=people,dc=example,dc=com`     | john9999 |
| mary     | password | `uid=mary,ou=people,dc=example,dc=com`      |          |
| mary0    | password | `uid=mary0,ou=people,dc=example,dc=com`     | mary9999 |
| bob      | password | `uid=bob,ou=people,dc=example-alt,dc=com`   |          |
| alice    | password | `uid=alice,ou=people,dc=example-alt,dc=com` |          |

For testing of GitLab Enterprise Edition the following groups are created.

| cn            | DN                                              | Members | Last          |
| -------       | --------                                        | ------- | ----          |
| group1        | `cn=group1,ou=groups,dc=example,dc=com`         | 2       |               |
| group2        | `cn=group2,ou=groups,dc=example,dc=com`         | 1       |               |
| group-10-0    | `cn=group-10-0,ou=groups,dc=example,dc=com`     | 10      | group-10-1000 |
| group-100-0   | `cn=group-100-0,ou=groups,dc=example,dc=com`    | 100     | group-100-100 |
| group-1000-0  | `cn=group-1000-0,ou=groups,dc=example,dc=com`   | 1,000   | group-1000-10 |
| group-10000-0 | `cn=group-10000-0,ou=groups,dc=example,dc=com`  | 10,000  | group-10000-1 |
| group-a       | `cn=group-a,ou=groups,dc=example-alt,dc=com`    | 2       |               |
| group-b       | `cn=group-b,ou=groups,dc=example-alt,dc=com`    | 1       |               |

## Elasticsearch

### Installation: OS X

1. Install Elasticsearch with [Homebrew]:

    ```sh
    brew install elasticsearch
    ```

1. Install the `delete-by-query` plugin:

    ```sh
    `brew info elasticsearch | awk '/plugin script:/ { print $NF }'` install delete-by-query
    ```

### Setup

1. Edit `gitlab-ee/config/gitlab.yml` to enable Elasticsearch:

    ```yaml
    ## Elasticsearch (EE only)
    # Enable it if you are going to use elasticsearch instead of
    # regular database search
    elasticsearch:
      enabled: true
      # host: localhost
      # port: 9200
    ```

1. Start Elasticsearch by either running `elasticsearch` in a new terminal, or
   by adding it to your `Procfile`:

    ```
    elasticsearch: elasticsearch
    ```

1. Be sure to restart the GDK's `foreman` instance if it's running.

1. Perform a manual update of the Elasticsearch indexes:

    ```sh
    cd gitlab-ee && bundle exec rake gitlab:elastic:index
    ```

## NFS

If you want to experiment with how GitLab behaves over NFS you can use a setup
where your development machine is simultaneously an NFS client and server, with
GitLab reading/writing data as the client.

### Ubuntu / Debian

```
sudo apt-get install -y nfs-kernel-server

# All our NFS exports (data on the 'server') is under /exports/gitlab-data
sudo mkdir -p /exports/gitlab-data/{repositories,gitlab-satellites,.ssh}
# We assume your developer user is git:git
sudo chown git:git /exports/gitlab-data/{repositories,gitlab-satellites,.ssh}

sudo mkdir /etc/exports.d
echo '/exports/gitlab-data 127.0.0.1(rw,sync,no_subtree_check)' | sudo tee /etc/exports.d/gitlab-data.exports
sudo service portmap restart
sudo service nfs-kernel-server restart
sudo exportfs -v 127.0.0.1:/exports/gitlab-data # should show /exports/gitlab-data

# We assume the current directory is the root of your gitlab-development-kit
sudo mkdir -p .ssh repositories gitlab-satellites
sudo mount 127.0.0.1:/exports/gitlab-data/.ssh .ssh
sudo mount 127.0.0.1:/exports/gitlab-data/repositories repositories
sudo mount 127.0.0.1:/exports/gitlab-data/gitlab-satellites gitlab-satellites
# TODO: put the above mounts in /etc/fstab ?
```

## HTTPS

If you want to access GitLab via HTTPS in development you can use
NGINX. On OS X you can install NGINX with `brew install nginx`.

First generate a key and certificate for localhost:

```
make localhost.crt
```

On OS X you can add this certificate to the trust store with:
`security add-trusted-cert localhost.crt`.

Next make sure that HTTPS is enabled in gitlab/config/gitlab.yml: look
for the `https:` and `port:` settings.

Uncomment the `nginx` line in your Procfile. Now `./run app`
(and `./run`) will start NGINX listening on https://localhost:3443.

If you are using a port other than localhost:3000 for
gitlab-workhorse, or if you want to use a port other than
localhost:3443 for NGINX, please edit `nginx/conf/nginx.conf`.

## SSH

If you want to work on GitLab's SSH integration then uncomment the
'sshd:' line in your Procfile. Next time you start `run` or `run app`
you will get an unprivileged SSH daemon process running on
localhost:2222, integrated with gitlab-shell.

To change the host/port you need to edit openssh/sshd_config and
gitlab/config/gitlab.yml. If you are not working on GitLab SSH
integration we recommend that you leave the 'sshd:' line in the
Procfile commented out.

## Performance metrics

See [doc/performance_metrics.md](doc/performance_metrics.md).

## Troubleshooting

### Rebuilding gems with native extensions

There may be times when your local libraries that are used to build some gems'
native extensions are updated (i.e., `libicu`), thus resulting in errors like:

```
rails-background-jobs.1 | /home/user/.rvm/gems/ruby-2.3.0/gems/activesupport-4.2.5.2/lib/active_support/dependencies.rb:274:in 'require': libicudata.so
cannot open shared object file: No such file or directory - /home/user/.rvm/gems/ruby-2.3.0/gems/charlock_holmes-0.7.3/lib/charlock_holmes/charlock_holmes.so (LoadError)
```

In that case, find the offending gem and use `pristine` to rebuild its native
extensions:

```bash
gem pristine charlock_holmes
```

### Error in database migrations when pg_trgm extension is missing

Since GitLab 8.6+ the PostgreSQL extension `pg_trgm` must be installed. If you
are installing GDK for the first time this is handled automatically from the
database schema. In case you are updating your GDK and you experience this
error, make sure you pull the latest changes from the GDK repository and run:

```bash
./support/enable-postgres-extensions
```

### Upgrading PostgreSQL

In case you are hit by `FATAL: database files are incompatible with server`,
you need to upgrade Postgres.

This is what to do when your OS/packaging system decides to install a new minor
version of Postgres:

1. (optional) Downgrade postgres
1. (optional) Make a sql-only GitLab backup
1. Rename/remove the gdk/postgresql/data directory: `mv postgresql/data{,.old}`
1. Run `make`
1. Build pg gem native extensions: `gem pristine pg`
1. (optional) Restore your gitlab backup

If things are working, you may remove the `postgresql/data.old` directory
completely.

### Rails cannot connect to Postgres

- Check if foreman is running in the gitlab-development-kit directory.
- Check for custom Postgres connection settings defined via the environment; we
  assume none such variables are set. Look for them with `set | grep '^PG'`.

### undefined symbol: SSLv2_method

This happens if your local OpenSSL library is updated and your Ruby binary is
built against an older version.

If you are using `rvm`, you should reinstall the Ruby binary. The following
command will fetch Ruby 2.3 and install it from source:

```
rvm reinstall --disable-binary 2.3
```

### Fix conflicts in database migrations if you use the same db for CE and EE

>**Note:**
The recommended way to fix the problem is to rebuild your database and move
your EE development into a new directory.

In case you use the same database for both CE and EE development, sometimes you
can get stuck in a situation when the migration is up in `rake db:migrate:status`,
but in reality the database doesn't have it.

For example, https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/3186
introduced some changes when a few EE migrations were added to CE. If you were
using the same db for CE and EE you would get hit by the following error:

```bash
undefined method `share_with_group_lock' for #<Group
```

This exception happened because the system thinks that such migration was
already run, and thus Rails skipped adding the `share_with_group_lock` field to
the `namespaces` table.

The problem is that you can not run `rake db:migrate:up VERSION=xxx` since the
system thinks the migration is already run. Also, you can not run
`rake db:migrate:redo VERSION=xxx` since it tries to do `down` before `up`,
which fails if column does not exist or can cause data loss if column exists.

A quick solution is to remove the database data and then recreate it:

```bash
rm -rf postgresql/data ; make
```

---

If you don't want to nuke the database, you can perform the migrations manually.
Open a terminal and start the rails console:

```bash
rails console
```

And run manually the migrations:

```
require Rails.root.join("db/migrate/20130711063759_create_project_group_links.rb")
CreateProjectGroupLinks.new.change
require Rails.root.join("db/migrate/20130820102832_add_access_to_project_group_link.rb")
AddAccessToProjectGroupLink.new.change
require Rails.root.join("db/migrate/20150930110012_add_group_share_lock.rb")
AddGroupShareLock.new.change
```

You should now be able to continue your development. You might want to note
that in this case we had 3 migrations happening:

```
db/migrate/20130711063759_create_project_group_links.rb
db/migrate/20130820102832_add_access_to_project_group_link.rb
db/migrate/20150930110012_add_group_share_lock.rb
```

In general it doesn't matter in which order you run them, but in this case
the last two migrations create columns in a table which is created by the first
migration. So, in this example the order is important. Otherwise you would try
to create a column in a non-existent table which would of course fail.

### 'LoadError: dlopen' when starting Ruby apps

This can happen when you try to load a Ruby gem with native extensions that
were linked against a system library that is no longer there. A typical culprit
is Homebrew on OS X, which encourages frequent updates (`brew update && brew
upgrade`) which may break binary compatibility.

```
bundle exec rake db:create dev:setup
rake aborted!
LoadError: dlopen(/Users/janedoe/.rbenv/versions/2.1.2/lib/ruby/gems/2.1.0/extensions/x86_64-darwin-13/2.1.0-static/charlock_holmes-0.6.9.4/charlock_holmes/charlock_holmes.bundle, 9): Library not loaded: /usr/local/opt/icu4c/lib/libicui18n.52.1.dylib
  Referenced from: /Users/janedoe/.rbenv/versions/2.1.2/lib/ruby/gems/2.1.0/extensions/x86_64-darwin-13/2.1.0-static/charlock_holmes-0.6.9.4/charlock_holmes/charlock_holmes.bundle
  Reason: image not found - /Users/janedoe/.rbenv/versions/2.1.2/lib/ruby/gems/2.1.0/extensions/x86_64-darwin-13/2.1.0-static/charlock_holmes-0.6.9.4/charlock_holmes/charlock_holmes.bundle
/Users/janedoe/gitlab-development-kit/gitlab/config/application.rb:6:in `<top (required)>'
/Users/janedoe/gitlab-development-kit/gitlab/Rakefile:5:in `require'
/Users/janedoe/gitlab-development-kit/gitlab/Rakefile:5:in `<top (required)>'
(See full trace by running task with --trace)
```

In the above example, you see that the charlock_holmes gem fails to load
`libicui18n.52.1.dylib`. You can try fixing this by re-installing
charlock_holmes:

```
# in /Users/janedoe/gitlab-development-kit
gem uninstall charlock_holmes
bundle install # should reinstall charlock_holmes
```

### 'bundle install' fails due to permission problems

This can happen if you are using a system-wide Ruby installation. You can
override the Ruby gem install path with `BUNDLE_PATH`:

```
# Install gems in (current directory)/vendor/bundle
make BUNDLE_PATH=$(pwd)/vendor/bundle
```

### 'bundle install' fails while compiling eventmachine gem

On OS X El Capitan, the eventmachine gem compilation might fail with:

```
Gem::Ext::BuildError: ERROR: Failed to build gem native extension.
<snip>
make "DESTDIR=" clean

make "DESTDIR="
compiling binder.cpp
In file included from binder.cpp:20:
./project.h:116:10: fatal error: 'openssl/ssl.h' file not found
#include <openssl/ssl.h>
         ^
1 error generated.
make: *** [binder.o] Error 1

make failed, exit code 2

```

To fix it:

```
bundle config build.eventmachine --with-cppflags=-I/usr/local/opt/openssl/include
```

and then do `bundle install` once again.

### 'Invalid reference name' when creating a new tag

Make sure that `git` is configured correctly on your development
machine (where GDK runs).

```
git checkout -b can-I-commit
git commit --allow-empty -m 'I can commit'
```


### 'gem install nokogiri' fails

Make sure that Xcode Command Line Tools installed on your development machine. For the discussion see this [issue](https://gitlab.com/gitlab-org/gitlab-development-kit/issues/124)

```
brew unlink gcc-4.2      # you might not need this step
gem uninstall nokogiri
xcode-select --install
gem install nokogiri
```


### Other problems

Please open an issue on the [GDK issue tracker](https://gitlab.com/gitlab-org/gitlab-development-kit/issues).

## Executables

A collection of executables can be found in the `bin/` directory. You can use
these executables by adding this directory to your shell's executable path. For
example, when using Bash:

    export PATH="${PATH}:path/to/gdk/bin"

### mount-slow-fs

This script can be used to mount a source directory at a given mount point via
SSHFS and slow down network traffic as a way of replicating a slow NFS. Usage of
this script is as following:

    mount-slow-fs path/to/actual/repositories /path/to/mountpoint

As an example, we'll use the following directories:

* Source directory: ~/Projects/repositories
* Mountpoint: /mnt/repositories

First create the mountpoint and set the correct permissions:

    sudo mkdir /mnt/repositories
    sudo chown $USER /mnt/repositories

Now we can run the script:

    mount-slow-fs ~/Projects/repositories /mnt/repositories

Terminating the script (using ^C) will automatically unmount the repositories
and remove the created traffic shaping rules.

## License

The GitLab Development Kit is distributed under the MIT license,
see the LICENSE file.

## GDK Setup
### Clone GitLab Development Kit repository

Moved to [doc/set-up-gdk.md](doc/set-up-gdk.md).

### Native installation setup

The sections below were moved to [doc/prepare.md](doc/prepare.md).

#### Prerequisites for all platforms
#### OS X 10.9 (Mavericks), 10.10 (Yosemite), 10.11 (El Capitan)
#### Ubuntu
#### Arch Linux
#### Debian
#### Fedora
#### CentOS
#### Other platforms

The sections above were moved to [doc/prepare.md](doc/prepare.md).

## Installation

The sections below were moved to [doc/set-up-gdk.md](doc/prepare.md).

### Develop in a fork
### Develop in the main repo
### GitLab Enterprise Edition
## Post-installation

The sections above were moved to [doc/set-up-gdk.md](doc/prepare.md).

[docker engine]: https://docs.docker.com/engine/installation/
[homebrew]: http://brew.sh/
[puias]: https://gitlab.com/gitlab-org/gitlab-recipes/tree/master/install/centos#add-puias-computational-repository
[vagrant]: http://www.vagrantup.com
[virtualbox]: https://www.virtualbox.org/wiki/Downloads

