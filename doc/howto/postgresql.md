## Accessing Postgres

GDK uses the Postgres binaries installed on your system
(see [install](../prepare.md) section), but keeps the Postgres
datafiles within the GDK directory structure, under `<gdk directory>/postgresql/data`.
This means that the databases cannot be seen with `psql -l`.

To access the database using `psql`, use the Rails `dbconsole` command.
Use `$RAILS_ENV` to access the test environment. For example:

```bash
cd gitlab-cd/gitlab
rails dbconsole
RAILS_ENV=test bundle exec rails dbconsole
```

To access the database using an external SQL editor, pass in the:

- Datafile path.
- Database port - e.g. `5432`
- Database name - e.g. `gitlabhq_development` or `gitlabhq_test`

![Postgres connect example](img/postgres_connect_example.png)

