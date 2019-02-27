# Configuration

This document describes ways how you can configure you GDK environment.

## Custom ports

You may want to customize the ports used by the services, so they can
coexist and be accessible when running multiple GDKs at the same time.

This may also be necessary when simulating some HA behavior or to run Geo.

Most of the time you want to use just the UNIX sockets, if possible,
but there are situations where sockets are not supported (for example
when using some Java-based IDEs).

### List of port files

Below is a list of all existing port configuration files and the
service they are related to:

| Port filename         | Service name                                  |
| --------------------- | --------------------------------------------- |
| `port`                | unicorn (rails)                               |
| `webpack_port`        | webpack-dev-server                            |
| `postgresql_port`     | main postgresql server                        |
| `postgresql_geo_port` | postgresql server for tracking database (Geo) |
| `registry_port`       | docker registry server                        |
| `gitlab_pages_port`   | gitlab-pages port                             |

### Using custom ports

To configure a custom port, create the corresponding port file with
just the port as the content, e.g.:

```sh
echo 3807 > webpack_port
```

## Makefile variables

This GitLab Development Kit tries to automatically adapt to your
environment. But in some cases, you still might want to override the
defaults.

To override the default variables used in [`Makefile`](../../Makefile),
you can create a file called `env.mk` at the root of your gdk. In this
file you can assign variables to override the defaults. The possible
variable assignment is:

- `postgres_bin_dir`: GDK automatically detects the directory of the
  PostgreSQL executables, but if you want to override that (e.g. to
  use a different version), use this variable.

- `jaeger_server_enabled`: By default, the GDK will launch an instance of
  the [Jaeger distributed tracing all-in-one
  server](http://localhost:16686/search). If you are running multiple
  copies of GDK, you should set `jaeger_server_enabled=false` in all but
  one GDK instance, and have traces get send to a single instance.

### Example

Here an example what `env.mk` might look like:

```makefile
postgres_bin_dir := /path/to/your/preferred/postgres/bin
```
