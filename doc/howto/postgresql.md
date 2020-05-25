# Accessing PostgreSQL

GDK uses the PostgreSQL binaries installed on your system (see [install](../prepare.md) section),
but keeps the datafiles within the GDK directory structure, under `<path to GDK>/gitlab-development-kit/postgresql/data`.

This means that the databases cannot be seen with `psql -l`, but you can use the `gdk psql` wrapper to
access the GDK databases:

```shell
# Connect to the default gitlabhq_development database
gdk psql

# List all databases
gdk psql -l

# Connect to a different database
gdk psql -d gitlabhq_test

# Show all options
gdk psql --help
```

You can also use the Rails `dbconsole` command, but it's much slower to start up:

```shell
cd <path to GDK>/gitlab

# Use default development environment
bundle exec rails dbconsole

# Use a different Rails environment
bundle exec rails dbconsole -e test
```

To access the database using an external SQL editor, such as [pgAdmin](https://www.pgadmin.org/), pass in the:

- Datafile path - e.g. `<path to GDK>/gitlab-development-kit/postgresql`
- Database port - e.g. `5432`
- Database name - e.g. `gitlabhq_development` or `gitlabhq_test`

![PostgreSQL connect example](img/postgres_connect_example.png)
