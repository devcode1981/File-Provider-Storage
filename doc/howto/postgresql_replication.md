# PostgreSQL replication

## Prerequisites

This guide assumes you've already set up one GDK instance with GitLab EE to act
as the **primary** Geo node in a `gdk-ee` folder. If not, follow the [Set up GDK
guide](../set-up-gdk.md#gitlab-enterprise-edition) before continuing!

## Configuring replication

For Gitlab Geo, you will need a master/slave database replication defined.
There are a few extra steps to follow:

In your primary instance (`gdk-ee`) you need to prepare the database for
replication. This requires the PostgreSQL server to be running, so we'll start
the server, perform the change (via a `make` task), and then kill and restart
the server to pick up the change:

```
cd gdk-ee

# terminal window 1:
foreman start postgresql

# terminal window 2:
make postgresql-replication-primary

# terminal window 1:
# stop foreman by hitting Ctrl-C, then restart it:
foreman start postgresql
```

Because we'll be replicating the primary database to the secondary, we need to
remove the secondary's PostgreSQL data folder:

```
# terminal window 2:
cd gdk-geo
rm -r postgresql
```

Now we need to add a symbolic link to the primary instance's data folder:

```
# From the gdk-geo folder:
ln -s ../gdk-ee/postgresql postgresql-primary
```

Initialize a slave database and setup replication:

```
# terminal window 2:
make postgresql-replication-secondary
```

Now you can go back to **terminal window 1** and stop `foreman` by hitting
<kbd>Ctrl-C</kbd>.

## Next steps

Continue to the [Post-installation
section](../set-up-gdk.md#post-installation) of the setup guide.
