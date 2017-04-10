# Set up GDK

## Clone GitLab Development Kit repository

Make sure that none of the directories 'above' GitLab Development Kit
contain 'problematic' characters such as ` ` and `(`. For example,
`/home/janedoe/projects` is OK, but `/home/janedoe/my projects` will
cause problems:

```
gem install gitlab-development-kit
gdk init
cd gitlab-development-kit
```

## Install GDK

The `gdk install` command will clone the repositories, install the Gem bundles and set up
basic configuration files. Pick one of the methods below. If you don't have
write access to the upstream repositories, you should use the 'Develop in a fork'
method.

### Develop in a fork

```
# Set up GDK with 'origin' pointing to your gitlab-ce fork.
# Replace MY-FORK with your namespace
gdk install gitlab_repo=https://gitlab.com/MY-FORK/gitlab-ce.git
support/set-gitlab-upstream
```

The `set-gitlab-upstream` script creates a remote named `upstream` for
[the canonical GitLab CE
repository](https://gitlab.com/gitlab-org/gitlab-ce). It also modifies
`gdk update` (See [Update gitlab and gitlab-shell
repositories](./howto/gdk_commands.md#update-gitlab-and-gitlab-shell-repositories))
to pull down from the upstream repository instead of your fork, making it
easier to keep up-to-date with the project.

If you want to push changes from upstream to your fork, run `gdk
update` and then `git push origin` from the `gitlab` directory.

### Develop in the main repo

Alternatively, you can clone all components from their official source.

```
gdk install
```

## GitLab Enterprise Edition

The recommended way to do development on GitLab Enterprise Edition is
to create a separate GDK directory for it. Below we call that
directory `gdk-ee`. We will configure GDK to start GitLab on port 3001
instead of 3000 so that you can run GDK EE next to CE without port
conflicts.

```
gem install gitlab-development-kit
gdk init gdk-ee
cd gdk-ee
echo 3001 > port
echo 3809 > webpack_port
gdk install gitlab_repo=https://gitlab.com/gitlab-org/gitlab-ee.git
```

Now you can start GitLab EE with `gdk run` in the `gdk-ee` directory and you
will not have port conflicts with a separate GDK instance for CE that
might still be running.

Instructions to generate a developer license can be found in the
onboarding document: https://about.gitlab.com/handbook/developer-onboarding/#gitlab-enterprise-edition-ee

### GitLab Geo

Development on GitLab Geo requires two Enterprise Edition GDK instances running
side-by-side. You can reuse the `gdk-ee` instance you set up in the previous
section as your primary node, and now we'll create a secondary instance in a
`gdk-geo` folder to act as a secondary node. We'll configure unique ports for
the new instance so that it can run alongside the primary.

```
gdk init gdk-geo
cd gdk-geo
echo 3002 > port
echo 3807 > webpack_port
gdk install gitlab_repo=https://gitlab.com/gitlab-org/gitlab-ee.git
```

Now that you've installed a primary and a secondary GDK instance, follow the
[PostgreSQL replication guide](./howto/postgresql_replication.md) before
continuing to "Post-installation" below.

## Post-installation

Start GitLab and all required services:

    gdk run

To start only the databases use:

    gdk run db

To start only the app (assuming the DBs are already running):

    gdk run app

To access GitLab you may now go to http://localhost:3000 in your
browser. The development login credentials are `root` and `5iveL!fe`.

You can override the port used by this GDK with a 'port' file.

    echo 4000 > port

Similarly, you can override the host (for example if you plan to use GDK inside a Docker container).

    echo 0.0.0.0 > host

If you want to work on GitLab CI you will need to install [GitLab Runner](https://gitlab.com/gitlab-org/gitlab-ci-multi-runner).

To enable the OpenLDAP server, see the OpenLDAP instructions in this [README](./howto/ldap.md).

After installation [learn how to use GDK](./howto/README.md).

