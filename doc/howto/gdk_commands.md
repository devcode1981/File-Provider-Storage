# GDK commands

## Running

To start up the GDK with all default enabled services, run:

```sh
gdk start
```

To see logs, run:

```sh
gdk tail
```

When you are not using GDK you may want to shut it down to free up
memory on your computer.

```sh
gdk stop
```

If you'd like to run a specific group of services, you can do so by providing
the service names as arguments. Multiple arguments are supported.

### Run just PostgreSQL and Redis

```sh
gdk start postgresql redis
```

## Update GitLab

To update `gitlab` and all of it's dependencies run the following command.

```sh
gdk update
```

It will also perform any possible migrations.

You can update gitlab separately by running `make gitlab-update`, or
update for example gitlab-shell with `make gitlab-shell-update`.

If there are changes in the local repositories or/and a different
branch than `master` is checked out, the `make update` commands will
stash any uncommitted changes and change to `master` branch prior to
updating the remote repositories.

## Update configuration files created by gitlab-development-kit

Sometimes there are changes in gitlab-development-kit that require
you to regenerate configuration files with `make`. You can always
remove an individual file (e.g. `rm Procfile`) and rebuild it by
running `make`. If you want to rebuild _all_ configuration files
created by GDK, run:

```sh
gdk reconfigure
```

## Configuration

With `gdk config` you can interact with the configuration of your
GDK. So far only `gdk config get` exists and it will print the
configuration for the `<setting>` you provide.

```sh
gdk config get <setting>
```

More information can be found in the [configuration documentation](configuration.md).
