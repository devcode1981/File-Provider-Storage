# PostgreSQL replication

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
