# Install, set up, and update GDK

> 🚨**Note:** Before undertaking these steps, be sure you have [prepared your system](prepare.md).🚨

To get GDK up and running:

1. [Install the `gitlab-development-kit` gem](#install-the-gitlab-development-kit-gem)
1. [Initialize a new GDK directory](#initialize-a-new-gdk-directory)
1. [Install GDK components](#install-gdk-components)

## Install the `gitlab-development-kit` gem

Execute the following with the Ruby version manager of your choice (`rvm`, `rbenv`, `chruby`, etc.)
with the current [`gitlab` Ruby version](https://gitlab.com/gitlab-org/gitlab/blob/master/.ruby-version):

```shell
gem install gitlab-development-kit
```

## Initialize a new GDK directory

1. Change into the directory where you want to store your source code for GitLab projects (e.g. `~/workspace`). The path used for
   GDK must contain only alphanumeric characters.

1. To initialize GDK into:

   - The default directory (`./gitlab-development-kit`), run:

     ```shell
     gdk init
     ```

   - A custom directory, pass a directory name. For example, to initialize into
     the `gdk` directory, run:

     ```shell
     gdk init gdk
     ```

## Install GDK components

1. Change into the newly created GDK directory. For example:

   ```shell
   cd gdk
   ```

1. Install the necessary components (repositories, Ruby gem bundles, and
   configuration) using `gdk install`.

   - For those who have write access to the [GitLab.org group](https://gitlab.com/gitlab-org)
     we recommend [Develop against the GitLab project](#develop-against-the-gitlab-project-default) (default)

   - Other options in order of recommendation:

     1. [Develop in your own GitLab fork](#develop-in-your-own-gitlab-fork)
     1. [Develop against the GitLab FOSS project](#develop-against-the-gitlab-foss-project)

### Develop against the GitLab project (default)

- HTTP, run:

  ```shell
  gdk install
  ```

- SSH, run:

  ```shell
  gdk install gitlab_repo=git@gitlab.com:gitlab-org/gitlab.git
  ```

Use `gdk install shallow_clone=true` for a faster clone that consumes less disk-space.
The clone will be done using [`git clone --depth=1`](https://www.git-scm.com/docs/git-clone#Documentation/git-clone.txt---depthltdepthgt).

### Develop against the GitLab FOSS project

> Learn [how to create a fork](https://docs.gitlab.com/ee/user/project/repository/forking_workflow.html#creating-a-fork)
> of [GitLab FOSS](https://gitlab.com/gitlab-org/gitlab-foss).

- HTTP, run:

  ```shell
  gdk install gitlab_repo=https://gitlab.com/gitlab-org/gitlab-foss.git
  ```

- SSH, run:

  ```shell
  gdk install gitlab_repo=git@gitlab.com:gitlab-org/gitlab-foss.git
  ```

Use `gdk install shallow_clone=true` for a faster clone that consumes less disk-space.
The clone will be done using [`git clone --depth=1`](https://www.git-scm.com/docs/git-clone#Documentation/git-clone.txt---depthltdepthgt).

### Develop in your own GitLab fork

> Learn [how to create a fork](https://docs.gitlab.com/ee/user/project/repository/forking_workflow.html#creating-a-fork)
> of [GitLab](https://gitlab.com/gitlab-org/gitlab).

- HTTP, run:

  ```shell
  # Replace <YOUR-NAMESPACE> with your namespace
  gdk install gitlab_repo=https://gitlab.com/<YOUR-NAMESPACE>/gitlab.git
  support/set-gitlab-upstream
  ```

- SSH, run:

  ```shell
  # Replace <YOUR-NAMESPACE> with your namespace
  gdk install gitlab_repo=git@gitlab.com:<YOUR-NAMESPACE>/gitlab.git
  support/set-gitlab-upstream
  ```

The `set-gitlab-upstream` script creates a remote named `upstream` for
[the canonical GitLab repository](https://gitlab.com/gitlab-org/gitlab). It also
modifies `gdk update` (See [Update GitLab](gdk_commands.md#update-gitlab))
to pull down from the upstream repository instead of your fork, making it easier
to keep up-to-date with the project.

If you want to push changes from upstream to your fork, run `gdk update` and then
`git push origin` from the `gitlab` directory.

## Map `gdk.test` host name to localhost

Set up a GDK-specific host name for convenience. For example, add the following to `/etc/hosts`:

```plaintext
127.0.0.1 gdk.test
```

The host name `gdk.test` is now available for documentation steps and GDK tools.

## Common errors during installation and troubleshooting

During `gdk install` process, you may encounter some dependencies related errors. Please refer to
the [Troubleshooting page](troubleshooting.md) or [open an issue on GDK tracker](https://gitlab.com/gitlab-org/gitlab-development-kit/issues)
if you get stuck.

## GitLab Enterprise Features

Instructions to generate a developer license can be found in the
[onboarding documentation](https://about.gitlab.com/handbook/developer-onboarding/#working-on-gitlab-ee).

The license key generator is only available for GitLab team members, who should use the "Sign in with GitLab"
link using their `dev.gitlab.org` account.

## Post-installation

Start GitLab and all required services:

```shell
gdk start
```

To stop the Rails app, which saves memory (useful when running tests):

```shell
gdk stop rails
```

To access GitLab, you may now go to <http://localhost:3000> in your browser.
It may take a few minutes for the Rails app to be ready. During this period you would see `dial unix /Users/.../gitlab.socket: connect: connection refused` in the browser.

The development login credentials are `root` and
`5iveL!fe`.

GDK comes with a number of settings, and most users will use the
default values, but you are able to override these in `gdk.yml` in the
GDK root.

For example, to change the port you can set this in your `gdk.yml`:

```yaml
port: 3001
```

And run the following command to apply:

```shell
gdk reconfigure
```

You can find a bunch of other settings that are configurable in `gdk.example.yml`.

Read the [configuration document](configuration.md) for more details.

After installation [learn how to use GDK](howto/index.md) enable other features.

### Running GitLab and GitLab FOSS concurrently

To have multiple GDK instances running concurrently, for example to
test GitLab and GitLab FOSS, initialize each into a separate GDK
folder. To run them simultaneously, make sure they don't use
conflicting port numbers.

You can for example use the following `gdk.yml` in one of both GDKs.

```yaml
port: 3001
webpack:
  port: 3809
gitlab_pages:
  port: 3011
```

## Update GDK

To update an existing GDK installation, run the following commands:

```shell
cd <gdk-dir>
gdk update
gdk reconfigure
```
