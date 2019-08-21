## Accessing Postgres

The GDK uses the Postges binaries installed on your system (see install section), but keeps the Postgres datafiles within the GDK directory structure, under `gdk-ce/postgresql/data` , which means that the databases cannot be seen with `psql -l`.

To access the database using `psql`, use the Rails dbconsole command. This can be prefixed to access the test environment.

```bash
cd gitlab-cd/gitlab
rails dbconsole
RAILS_ENV=test rails dbconsole
```

To access the database using an external SQL editor, pass in the datafile path, port and the database name.

![Postgres connect example](img/postgres_connect_example.png)

