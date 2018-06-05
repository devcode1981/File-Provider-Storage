# Set up GDK

## Clone GitLab Development Kit repository

Make sure that none of the directories 'above' GitLab Development Kit
contain 'problematic' characters such as ` ` and `(`. For example,
`/home/janedoe/projects` is OK, but `/home/janedoe/my projects` will
cause problems.

Execute the following with the Ruby version manager of your choice (`rvm`, `rbenv`, `chruby`, etc.) with the current [`gitlab-ce` Ruby version](https://gitlab.com/gitlab-org/gitlab-ce/blob/master/.ruby-version):

```
gem install gitlab-development-kit
gdk init
```

The GDK is now cloned into `./gitlab-development-kit`. Enter that directory. Note that this is the default instantiation directory for the `gdk init` command.

If you plan to work with **CE** and **EE** versions side by side, it is recommended that you name the GDK instance during `init` and not use the default directory name. Pick a good naming convention that will allow you to differentiate and switch between the two versions easily.

For example:
```
gdk init gdk-ce
```

## Install GDK

The `gdk install` command will clone the repositories, install the Gem bundles and set up
basic configuration files. Pick one of the methods below. If you don't have
write access to the upstream repositories, you should use the 'Develop in a fork'
method.

In either case, use your Ruby version manager to run `gdk install` with the `gitlab-ce` Ruby version. The `gdk install` command will install from `https://gitlab.com/gitlab-org/gitlab-ce.git` by default.

### Option 1: Develop in a fork

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

If you want to push changes from upstream to your fork, run `gdk update` and then `git push origin` from the `gitlab` directory.

### Option 2: Develop in the main repo

Alternatively, you can clone all components from their official source.

```
gdk install
```

## GitLab Enterprise Edition

The recommended way to do development on GitLab Enterprise Edition is
to create a separate GDK directory for it. Below we call that
directory `gdk-ee` following the naming convention from above. We will configure GDK to start GitLab on port 3001
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
onboarding document: https://about.gitlab.com/handbook/developer-onboarding/#working-on-gitlab-ee

License key generator is only available for GitLab employees.

### GitLab Geo

Check the [GitLab Geo instructions](./howto/geo.md).

## Post-installation

Start GitLab and all required services:

```sh
gdk run
```

To start only the databases use:

```sh
gdk run db
```

To start only the app (assuming the DBs are already running):

```sh
gdk run app
```

To access GitLab you may now go to http://localhost:3000 in your
browser. The development login credentials are `root` and `5iveL!fe`.

If you like, you can override the port, host, or relative URL root by adding the appropriate file to the GDK root. You'll need to reconfigure and restart the GDK for these changes to take effect.

```sh
echo 4000 > port

# This can be useful if you plan to use GDK inside a Docker container
echo 0.0.0.0 > host

echo /gitlab > relative_url_root

gdk reconfigure
```

You can also override the host name used by the Rails instance (specified by the `host` value in `gitlab/config/gitlab.yml`).

```sh
 echo my.gitlab.dev > hostname

 gdk reconfigure
 ```

If you want to work on GitLab CI you will need to install [GitLab Runner](https://gitlab.com/gitlab-org/gitlab-runner).

To enable the OpenLDAP server, see the OpenLDAP instructions in this [README](./howto/ldap.md).

After installation [learn how to use GDK](./howto/README.md).
