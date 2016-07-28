# Set up GDK

## Clone GitLab Development Kit repository

Make sure that none of the directories 'above' GitLab Development Kit
contain 'problematic' characters such as ` ` and `(`. For example,
`/home/janedoe/projects` is OK, but `/home/janedoe/my projects` will
cause problems.

```
git clone https://gitlab.com/gitlab-org/gitlab-development-kit.git
cd gitlab-development-kit
```

The `Makefile` will clone the repositories, install the Gem bundles and set up
basic configuration files. Pick one:

## Develop in a fork

```
# Set up GDK with 'origin' pointing to your gitlab-ce fork.
# Replace MY-FORK with your namespace
make gitlab_repo=https://gitlab.com/MY-FORK/gitlab-ce.git
support/set-gitlab-upstream
```

The set-gitlab-upstream script creates a remote named `upstream` for
[the canonical GitLab CE
repository](https://gitlab.com/gitlab-org/gitlab-ce). It also modifies
`make update` (See [Update gitlab and gitlab-shell
repositories](Update gitlab and gitlab-shell repositories)) to pull
down from the upstream repository instead of your fork, making it
easier to keep up-to-date with the project.

If you want to push changes from upstream to your fork, run `make
update` and then `git push origin` from the `gitlab` directory.

## Develop in the main repo

Alternatively, you can clone all components from their official source.

```
# Clone your own forked repositories
make
```


If you are going to work on Gitlab Geo, you will need [PostgreSQL replication](#postgresql-replication) setup before the "Post-installation" instructions.

## GitLab Enterprise Edition

The recommended way to do development on GitLab Enterprise Edition is
to create a separate GDK directory for it. Below we call that
directory `gdk-ee`. We will configure GDK to start GitLab on port 3001
instead of 3000 so that you can run GDK EE next to CE without port
conflicts.

```
git clone https://gitlab.com/gitlab-org/gitlab-development-kit.git gdk-ee
cd gdk-ee
echo 3001 > port
make gitlab_repo=https://gitlab.com/gitlab-org/gitlab-ee.git
```

Now you can start GitLab EE with `./run` in the `gdk-ee` directory and you
will not have port conflicts with a separate GDK instance for CE that
might still be running.

Instructions to generate a developer license can be found in the
onboarding document: https://about.gitlab.com/handbook/developer-onboarding/#gitlab-enterprise-edition-ee

## Post-installation

Start GitLab and all required services:

    ./run

To start only the databases use:

    ./run db

To start only the app (assuming the DBs are already running):

    ./run app

To access GitLab you may now go to http://localhost:3000 in your
browser. The development login credentials are `root` and `5iveL!fe`.

You can override the port used by this GDK with a 'port' file.

    echo 4000 > port

If you want to work on GitLab CI you will need to install [GitLab Runner](https://gitlab.com/gitlab-org/gitlab-ci-multi-runner).

To enable the OpenLDAP server, see the OpenLDAP instructions in this readme.

END Post-installation

Please do not delete the 'END Post-installation' line above. It is used to
print the post-installation message from the `Makefile`.
