# PostgreSQL replication

For Gitlab Geo, you will need a master/slave database replication defined.
There are a few extra steps to follow:

In your primary instance (`gdk-ee`) you need to prepare the database for
replication:

```
cd gdk-ee
# terminal window 1:
foreman start postgresql

# terminal window 2:
make postgresql-replication-primary

# go back to terminal window 1 stop foreman by hitting "CTRL-C" and execute it again with:
foreman start postgresql
```

You must start with a clean postgres setup on the secondary node:

```
# terminal window 2:
cd ../gdk-geo
rm -rf postgresql
```

You need to setup a symbolic link to the `postgresql` folder from the
primary instance (`gdk-ee`):

```
# you must be in `gdk-geo` folder
ln -s ../gdk-ee/postgresql postgresql-primary
```

Initialize a slave database and setup replication:

```
# terminal window 2:
make postgresql-replication-secondary
# go back to terminal window 1 and stop foreman by hitting "CTRL-C"
```
