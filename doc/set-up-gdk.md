# Set up GDK

> 🚨**Note:** Before undertaking these steps, be sure you have [prepared your system](./prepare.md).🚨

To get GDK up and running:

1. [Install the `gitlab-development-kit` gem](#install-the-gitlab-development-kit-gem)
1. [Initialize a new GDK directory](#initialize-a-new-gdk-directory)
1. [Install GDK components](#install-gdk-components)

## Install the `gitlab-development-kit` gem

Execute the following with the Ruby version manager of your choice (`rvm`, `rbenv`, `chruby`, etc.) with the current [`gitlab` Ruby version](https://gitlab.com/gitlab-org/gitlab/blob/master/.ruby-version):

```sh
gem install gitlab-development-kit
```

## Initialize a new GDK directory

1. Change into the directory where you store your source code. The path used for
   GDK must contain only alphanumeric characters.

1. To initialize GDK into:

  - The default directory (`./gitlab-development-kit`), run:

    ```sh
    gdk init
    ```

  - A custom directory, pass a directory name. For example, to initialize into
    the `gdk` directory, run:

      ```sh
      gdk init my_gitlab_development_kit
      ```

## Install GDK components

1. Change into the newly created GDK directory.  For example:

   ```sh
   cd gitlab-development-kit
   ```

   If you specified a custom directory like `my_gitlab_development_kit` above, be
   sure to use that instead.

1. Install the necessary components (repositories, Ruby gem bundles, and
   configuration) using `gdk install`.

   - For those who have write access to the [GitLab.org group](https://gitlab.com/gitlab-org)
   we recommend [Develop against the GitLab project](#develop-against-the-gitlab-project-default) (default)

   - Other options in order of recommendation:

     1. [Develop in your own GitLab fork](#develop-in-your-own-gitlab-fork)
     1. [Develop against the GitLab project](#develop-against-the-gitlab-project-default)
     1. [Develop against the GitLab FOSS project](#develop-against-the-gitlab-foss-project)

### Develop against the GitLab project (default)

- HTTP, run:

  ```sh
  gdk install
  ```

- SSH, run:

  ```sh
  gdk install gitlab_repo=git@gitlab.com:gitlab-org/gitlab.git
  ```

Use `gdk install shallow_clone=true` for a faster clone that consumes less disk-space.
The clone will be done using [`git clone --depth=1`](https://www.git-scm.com/docs/git-clone#Documentation/git-clone.txt---depthltdepthgt).

### Develop against the GitLab FOSS project

- HTTP, run:

  ```sh
  gdk install gitlab_repo=https://gitlab.com/gitlab-org/gitlab-foss.git
  ```

- SSH, run:

  ```sh
  gdk install gitlab_repo=git@gitlab.com:gitlab-org/gitlab-foss.git
  ```

Use `gdk install shallow_clone=true` for a faster clone that consumes less disk-space.
The clone will be done using [`git clone --depth=1`](https://www.git-scm.com/docs/git-clone#Documentation/git-clone.txt---depthltdepthgt).

### Develop in your own GitLab fork

- HTTP, run:

  ```sh
  # Replace <YOUR-NAMESPACE> with your namespace
  gdk install gitlab_repo=https://gitlab.com/<YOUR-NAMESPACE>/gitlab.git
  support/set-gitlab-upstream
  ```

- SSH, run:

  ```sh
  # Replace <YOUR-NAMESPACE> with your namespace
  gdk install gitlab_repo=git@gitlab.com:<YOUR-NAMESPACE>/gitlab.git
  support/set-gitlab-upstream
  ```

The `set-gitlab-upstream` script creates a remote named `upstream` for
[the canonical GitLab repository](https://gitlab.com/gitlab-org/gitlab). It also
modifies `gdk update` (See [Update gitlab and gitlab-shell repositories](./howto/gdk_commands.md#update-gitlab-and-gitlab-shell-repositories))
to pull down from the upstream repository instead of your fork, making it easier
to keep up-to-date with the project.

If you want to push changes from upstream to your fork, run `gdk update` and then
`git push origin` from the `gitlab` directory.

## Common errors during installation and troubleshooting

During `gdk install` process, you may encounter some dependencies related errors. Please refer to the [Troubleshooting page](./howto/troubleshooting.md) or [open an issue on GDK tracker](https://gitlab.com/gitlab-org/gitlab-development-kit/issues) if you get stuck.

## GitLab Enterprise Features

Instructions to generate a developer license can be found in the
onboarding document: https://about.gitlab.com/handbook/developer-onboarding/#working-on-gitlab-ee

The license key generator is only available for GitLab employees, who should use the "Sign in with GitLab" link using their dev.gitlab.org account.

## Post-installation

Start GitLab and all required services:

```sh
gdk start
```

To stop the Rails app, which saves memory (useful when running tests):

```sh
gdk stop rails
```

To access GitLab, you may now go to http://localhost:3000 in your
browser. The development login credentials are `root` and
`5iveL!fe`.

GDK comes with a number of settings, and most users will use the
default values, but you are able to override these in `gdk.yml` in the
GDK root.

For example, to change the port you can set this in your `gdk.yml`:

```yaml
port: 3001
```

And run the following command to apply:

```sh
gdk reconfigure
```

You can find a bunch of other settings that are configurable in `gdk.example.yml`.

Read the [configuration document](howto/configuration.md) for more details.

After installation [learn how to use GDK](howto/README.md) enable other features.

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
