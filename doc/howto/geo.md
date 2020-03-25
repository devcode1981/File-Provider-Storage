# GitLab Geo

This document will instruct you to set up GitLab Geo using GDK.

Geo allows you to replicate a whole GitLab instance. Customers use this for
Disaster Recovery, as well as to offload read-only requests to secondary
instances. For more, see
[GitLab Geo](https://about.gitlab.com/solutions/geo/) or
[Replication (Geo)](https://docs.gitlab.com/ee/administration/geo/replication/).

## Prerequisites

Development on GitLab Geo requires two GDK instances running side-by-side.
You can use an existing `gdk` instance based on the [Set up GDK](../set-up-gdk.md#develop-against-the-gitlab-project-default) documentation as the primary node.

### Primary

Add the following to `gdk.yml` file on the primary node:

```yaml
---
geo:
  enabled: true
```

Though this setting normally indicates the node is a secondary, many scripts and `make` targets
assume they can run secondary-specific logic on any node. That is, rather than the scripts being
node-type aware, this ensures the primary can act "like a secondary" in some cases
such as when running tests.

### Secondary

Now we'll create a secondary instance in a `gdk-geo` folder to act as
a secondary node. We'll configure unique ports for the new instance so
that it can run alongside the primary.

```bash
gdk init gdk-geo
cd gdk-geo
```

Add the following to `gdk.yml` file:

```yaml
---
geo:
  enabled: true
  node_name: gdk-geo
gitlab_pages:
  enabled: true
  port: 3011
tracer:
  jaeger:
    enabled: false
port: 3001
webpack:
  port: 3809
```

Then run the following command:

```bash
# Assuming your primary GDK instance lives in parallel folders:
gdk install gitlab_repo=../gdk/gitlab
```

When seeding begins, cancel it (Ctrl-C) since we will delete the data anyway.

Then run the following commands:

```bash
gdk start postgresql
gdk start postgresql-geo
make geo-setup
```

## Database replication

For GitLab Geo, you will need a primary/secondary database replication defined.
There are a few extra steps to follow.

### Prepare primary for replication

In your primary instance (`gdk`) you need to prepare the database for
replication. This requires the PostgreSQL server to be running, so we'll start
the server, perform the change (via a `make` task), and then kill and restart
the server to pick up the change:

```bash
# terminal window 1:
cd gdk
gdk start postgresql
make postgresql-replication-primary
gdk restart postgresql
make postgresql-replication-primary-create-slot
gdk restart postgresql
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
ln -s ../gdk/postgresql postgresql-primary
```

Initialize a secondary database and setup replication:

```bash
# terminal window 2:
make postgresql-replication-secondary
```

### Running tests

#### On a primary

The secondary has a read-write tracking database, which is necessary for some
Geo tests to run. However, its copy of the replicated database is read-only, so
tests will fail to run.

You can add the tracking database to the primary node by running:

```bash
# From the gdk folder:
gdk start

# In another terminal window
make geo-setup
```

This will add both development and test instances, but the primary will continue
to operate *as* a primary except in tests where the current Geo node has been
stubbed.

To ensure the tracking database is started, restart GDK. You will need to use
`gdk start` to be able to run the tests.

#### On a secondary

When you try to run tests on a GDK configured as a Geo secondary, tests
might fail because the main database is read-only.

You can work around this by using the PostgreSQL instance that is used
for the tracking database (i.e. the one running in
`<secondary-gdk-root>/postgresql-geo`) for both the tracking and the
main database.

Add or replace the `test:` block with the following to `<secondary-gdk-root>/gitlab/config/database.yml`:

```yaml
test: &test
  adapter: postgresql
  encoding: unicode
  database: gitlabhq_test
  host: /home/<secondary-gdk-root>/postgresql-geo
  port: 5432
  pool: 10
```

Now run the following to ensure the database and FDW schema are setup:

```sh
# Within the <secondary-gdk-root>/gitlab folder:
bin/rake db:test:prepare

# Within the <secondary-gdk-root> folder:
make postgresql/geo-fdw/test/rebuild
```

## Copy database encryption key

The primary and the secondary nodes will be using the same secret key
to encrypt attributes in the database. To copy the secret from your primary to your secondary:

1. Open `gdk/gitlab/config/secrets.yml` with your editor of choice
1. Copy the value of `development.db_key_base`
1. Paste it into `gdk-geo/gitlab/config/secrets.yml`

## SSH cloning

To be able to clone over SSH on a secondary, follow the instruction on how
to set up [SSH](ssh.md), including [SSH key lookup from database](ssh.md#ssh-key-lookup-from-database).

## Configure Geo nodes

### Add primary node

There is a rake task that can add the primary node:

```bash
cd gdk/gitlab

bundle exec rake geo:set_primary_node
```

### Add secondary node

There isn't a convenient rake task to add the secondary node because the relevant
data is on the secondary, but we can only write to the primary database. So we
must get the values from the secondary, and then manually add the node.

1. In a terminal, change to the `gitlab` directory of the secondary node:

   ```bash
   cd gdk-geo/gitlab
   ```

1. Output the secondary node's **Name** and **URL**:

   ```bash
   bundle exec rails runner 'puts "Name: #{GeoNode.current_node_name}"; puts "URL: #{GeoNode.current_node_url}"'
   ```

1. Visit the **primary** node's **Admin Area > Geo > Nodes** (`/admin/geo/nodes`)
   in your browser.
1. Click the **New node** button.
1. Fill in the **Name** and **URL** fields for the **secondary** node, using the *exact* values from step 2.
1. **Do not** check the box 'This is a primary node'.
1. Click the **Add node** button.

![Adding a secondary node](img/adding_a_secondary_node.png)

## Geo-specific GDK commands

Use the following commands to keep Geo-enabled GDK installations up to date.

- `make geo-primary-update`, run on the primary GDK node.
- `make geo-secondary-update`, run on any secondary GDK nodes.

## Troubleshooting

### `postgresql-geo/data` exists but is not empty

If you see this error during setup because you have already run `make geo-setup` once:

```plaintext
initdb: directory "postgresql-geo/data" exists but is not empty
If you want to create a new database system, either remove or empty
the directory "postgresql-geo/data" or run initdb
with an argument other than "postgresql-geo/data".
make: *** [postgresql/geo] Error 1
```

Then you may delete or move that data in order to run `make geo-setup` again.

```bash
mv postgresql-geo/data postgresql-geo/data.backup
```

### GDK update command error on secondaries

You will see the following error after running `gdk update` on your local Geo
secondary. It is ok to ignore. Your local Geo secondary does not have or need a
test DB, and this error occurs on the very last step of `gdk update`.

```bash
cd /Users/foo/Developer/gdk-geo/gitlab && \
      bundle exec rake db:migrate db:test:prepare
rake aborted!
ActiveRecord::StatementInvalid: PG::ReadOnlySqlTransaction: ERROR:  cannot execute DROP DATABASE in a read-only transaction
: DROP DATABASE IF EXISTS "gitlabhq_test"
/Users/foo/.rbenv/versions/2.6.3/bin/bundle:23:in `load'
/Users/foo/.rbenv/versions/2.6.3/bin/bundle:23:in `<main>'

Caused by:
PG::ReadOnlySqlTransaction: ERROR:  cannot execute DROP DATABASE in a read-only transaction
/Users/foo/.rbenv/versions/2.6.3/bin/bundle:23:in `load'
/Users/foo/.rbenv/versions/2.6.3/bin/bundle:23:in `<main>'
Tasks: TOP => db:test:load => db:test:purge
(See full trace by running task with --trace)
make: *** [gitlab-update] Error 1
```

### FDW is no longer working even though you have it enabled, after migrations or `gdk update`

You need to rebuild FDW tables.

If your local primary is in `~/Developer/gdk`:

```bash
cd ~/Developer/gdk
gdk start
make postgresql/geo-fdw/test/rebuild
```

And if your local secondary is in `~/Developer/gdk-geo`:

```bash
cd ~/Developer/gdk-geo
gdk start
make postgresql/geo-fdw/development/rebuild
```

Also see [Useful aliases](#useful-aliases) above.

## Enabling Docker Registry replication

For information on enabling Docker Registry replication in GDK, see
[Docker Registry replication](geo-docker-registry-replication.md).
