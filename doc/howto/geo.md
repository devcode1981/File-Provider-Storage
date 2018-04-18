# GitLab Geo

This document will instruct you to set up GitLab Geo using GDK.

## Prerequisites

Development on GitLab Geo requires two Enterprise Edition GDK
instances running side-by-side. You can use an existing `gdk-ee`
instance from the [set-up](../set-up-gdk.md#gitlab-enterprise-edition)
as primary node.

### Secondary

Now we'll create a secondary instance in a `gdk-geo` folder to act as
a secondary node. We'll configure unique ports for the new instance so
that it can run alongside the primary.

```bash
gdk init gdk-geo
cd gdk-geo
echo 3002 > port
echo 3807 > webpack_port
gdk install gitlab_repo=../gdk-ee/gitlab
# You can cancel (Ctrl-C) seeding when it gets to that point since we will delete the data anyway
gdk run db
make geo-setup
```

## Database replication

For Gitlab Geo, you will need a master/slave database replication defined.
There are a few extra steps to follow:

### Prepare primary for replication

In your primary instance (`gdk-ee`) you need to prepare the database for
replication. This requires the PostgreSQL server to be running, so we'll start
the server, perform the change (via a `make` task), and then kill and restart
the server to pick up the change:

```bash
cd gdk-ee

# terminal window 1:
foreman start postgresql

# terminal window 2:
make postgresql-replication-primary

# terminal window 1:
# stop foreman by hitting Ctrl-C, then restart it:
foreman start postgresql

# terminal window 2:
make postgresql-replication-primary-create-slot

# terminal window 1:
# stop foreman by hitting Ctrl-C, then restart it:
foreman start postgresql
```

### Set up replication on secondary

Because we'll be replicating the primary database to the secondary, we need to
remove the secondary's PostgreSQL data folder:

```bash
# terminal window 2:
cd gdk-geo
rm -r postgresql
```

Now we need to add a symbolic link to the primary instance's data folder:

```bash
# From the gdk-geo folder:
ln -s ../gdk-ee/postgresql postgresql-primary
```

Initialize a slave database and setup replication:

```bash
# terminal window 2:
make postgresql-replication-secondary
```

Now you can go back to **terminal window 1** and stop `foreman` by hitting
<kbd>Ctrl-C</kbd>.

### Running tests

The secondary has a read-write tracking database, which is necessary for some
Geo tests to run. However, its copy of the replicated database is read-only, so
tests will fail to run.

You can add the tracking database to the primary node by running:

```bash
# From the gdk-ee folder:
make geo-setup
```

This will add both development and test instances, but the primary will continue
to operate *as* a primary except in tests where the current Geo node has been
stubbed.

To ensure the tracking database is started, restart GDK. You will need to use
`gdk run`, rather than `gdk run db`, to run the tests.

## Copy database encryption key

The primary and the secondary nodes will be using the same secret key
to encrypt attributes in the database. To copy the secret from your primary to your secondary:

1. Open `gdk-ee/gitlab/config/secrets.yml` with your editor of choice
1. Copy the value of `development.db_key_base`
1. Paste it into `gdk-geo/gitlab/config/secrets.yml`

## SSH cloning

To be able to clone over SSH on a secondary, follow the instruction on how
to set up [SSH](ssh.md), including [SSH key lookup from database](ssh.md#ssh-key-lookup-from-database).

## Configure Geo nodes

### Add primary node

1. Visit the **primary** node's **Admin Area ➔ Geo Nodes** (`/admin/geo_nodes`)
   in your browser.
1. Fill in the full URL of the primary, e.g. `http://localhost:3001/`
1. Check the box 'This is a primary node'.
1. Click the **Add node** button.

### Add secondary node

1. Visit the **primary** node's **Admin Area ➔ Geo Nodes** (`/admin/geo_nodes`)
   in your browser.
1. Fill in the full URL of the secondary, e.g. `http://localhost:3002/`
1. **Do not** check the box 'This is a primary node'.
1. Click the **Add node** button.
