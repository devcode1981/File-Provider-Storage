# GDK commands

## Running

To start up the GDK with all default enabled services, run:

```sh
gdk run
```

If you'd like to run a specific group of services, you can do so by providing
the service group names as arguments.  Multiple arguments are supported:

### Run just DB services

```sh
gdk run db
```

### Run DB and Geo DB services

```sh
gdk run db geo_db
```

## Update gitlab and gitlab-shell repositories

When working on a new feature, always check that your `gitlab` repository is up
to date with the upstream master branch.

In order to fetch the latest code, first make sure that `foreman` for
postgres is runnning (needed for db migration) and then run:

```sh
gdk update
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
created by the Makefile, run:

```sh
gdk reconfigure
```
