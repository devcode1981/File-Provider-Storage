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

```
gdk init gdk-geo
cd gdk-geo
echo 3002 > port
echo 3807 > webpack_port
gdk install gitlab_repo=https://gitlab.com/gitlab-org/gitlab-ee.git
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

```shell
cd gdk-ee

# terminal window 1:
foreman start postgresql

# terminal window 2:
make postgresql-replication-primary

# terminal window 1:
# stop foreman by hitting Ctrl-C, then restart it:
foreman start postgresql
```

### Set up replication on secondary

Because we'll be replicating the primary database to the secondary, we need to
remove the secondary's PostgreSQL data folder:

```shell
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

## Known hosts

The secondary will connect to the primary by SSH to synchronize
repositories. To make sure the secondary recognizes the primary as
known host, make sure you have connected at least once to your primary
node from your local machine (the secondary will use your default
known hosts from `~/.ssh/known_hosts`).

## Copy database encryption key

The primary and the secondary nodes will be using the same secret key
to encrypt attributes in the database. To copy the secret from your primary to your secondary:

1. Open `gdk-ee/gitlab/config/secrets` with your editor of choice
1. Copy the value of `development.db_key_base`
1. Paste it into `gdk-geo/gitlab/config/secrets`

## Store SSH keys in database

GitLab Geo requires SSH keys storage in the database. Check the
[official documentation](https://docs.gitlab.com/ee/administration/operations/speed_up_ssh.html#the-solution).

The executable configured at `AuthorizedKeysCommand`, and all of its
parent directories, should be owned by `root`. For example, you can
place it in the directory as documented:
`/opt/gitlab-shell/authorized_keys`

## Configure Geo nodes

### Add primary node

1. Visit the **primary** node's **Admin Area ➔ Geo Nodes** (`/admin/geo_nodes`)
   in your browser.
1. Fill in the full URL of the primary, e.g. `http://localhost:3001/`
1. Check the box 'This is a primary node'.
1. Fill in the public key. You can take it from
   `gdk-ee/openssh/ssh_host_rsa_key.pub`
1. Click the **Add node** button.

### Add secondary node

1. Visit the **primary** node's **Admin Area ➔ Geo Nodes** (`/admin/geo_nodes`)
   in your browser.
1. Fill in the full URL of the secondary, e.g. `http://localhost:3002/`
1. **Do not** check the box 'This is a primary node'.
1. Fill in the public key. You can take it from
   `gdk-geo/openssh/ssh_host_rsa_key.pub`
1. Click the **Add node** button.

You need to make sure when the secondary has SSH access to all the git
repositories on the primary. To pull from the primary, the secondary
will probably use your default ssh key (at `~/.ssh/id_rsa`). So there
are 2 options to configure this:

- Add your default public key `~/.ssh/id_rsa.pub` to an admin account (you
  might already have this).
- Use your default public key `~/.ssh/id_rsa.pub` while configuring
  the secondary node (see above).

Doing both is not possible, because all SSH key fingerprints should
be unique.
