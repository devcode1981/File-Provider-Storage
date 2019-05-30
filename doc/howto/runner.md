# Using GitLab Runner with GDK

Most features of [GitLab CI](http://docs.gitlab.com/ce/ci/) need a
[Runner](http://docs.gitlab.com/ce/ci/runners/README.html) to be registered with
the GitLab installation. This HOWTO will take you through the necessary steps to
do so when GitLab is running under GDK.

## Set up GitLab

Start by [preparing your computer](../prepare.md) and
[setting up GDK](../set-up-gdk.md).

In some configurations, GitLab Runner needs access to GitLab from inside a
Docker container, or even another machine, which isn't supported in the default
configuration.

### Simple configuration

If you intend to just use the "shell" executor (fine for very
simple jobs), you can use GDK with its default settings and skip the Advanced
configuration below. If GDK is already running, you'll need to restart it after making
these changes.

With GDK running:

1. Navigate to `http://localhost:3000/admin/runners` (log in as root)
1. Make note of the `Registration token`.

### Advanced configuration

Ensure you have Docker installed, then set up GitLab to bind to all
IPs on your machine by following [these instructions](local_network.md)
(in short: `echo "0.0.0.0" > host` in the GDK root directory). Without this
step, builds will fail with a 'connection refused' error.

The `gitlab/config/gitlab.yml` configuration file also needs tweaking - find
this section:

```yaml
production: &base
  #
  # 1. GitLab app settings
  # ==========================

  ## GitLab settings
  gitlab:
    ## Web server settings (note: host is the FQDN, do not include http://)
    host: localhost
```

The `host` parameter needs to be changed from `localhost` to an IP address that
*actually exists on the computer*. `0.0.0.0` is not valid - run `ipconfig`
(Windows), `ifconfig` (Mac, BSD) or `ip addr show` (Linux) to get a list of IPs.
The right one to use depends on your network, and may change from time to time,
but an address like `10.x.x.x`, `172.16.x.x` or `192.168.x.x` is normally the
right one.

Now run GDK: `gdk run`. Navigate to `http://<ip>:3000/gitlab-org/gitlab-test`.
If the URL doesn't work, repeat the last step and pick a different IP.

Once there, ensure that the HTTP clone URL is `http://<ip>:3000/gitlab-org/gitlab-test.git`.
If it points to `localhost` instead, `gitlab/config/gitlab.yml` is incorrect.

Finally, navigate to `http://<ip>:3000/admin/runners` (log in as root) and make
a note of the `Registration token`.

## Download GitLab Runner

Unless you want to make changes to the Runner, it's easiest to install a binary
package. Follow the
[installation instructions](https://docs.gitlab.com/runner/install/)
for your operating system
([Linux](https://docs.gitlab.com/runner/install/linux-repository.html),
[OSX](https://docs.gitlab.com/runner/install/osx.html),
[Windows](https://docs.gitlab.com/runner/install/windows.html)).

To build from source, you'll need to set up a development environment manually -
GDK doesn't manage it for you. The official GitLab Runner repository is
[here](https://gitlab.com/gitlab-org/gitlab-runner); just follow
[the development instructions](https://docs.gitlab.com/runner/development/).

All the methods should (eventually) create a `gitlab-runner` binary.

## Setting up the Runner

Run `gitlab-runner register --run-untagged --config <path-to-gdk>/gitlab-runner-config.toml`
(as your normal user), and follow the prompts. Use `http://localhost:3000/`
for the coordinator URL, and the `Registration token` as the `gitlab-ci token`.
The Runner will write its configuration file to `gitlab-runner-config.toml`,
which is in GDK's `.gitignore` file.

If Docker is installed and you followed the special setup instructions above,
choose `docker` as the executor. Otherwise, choose `shell` - but remember that
builds will then be run directly on the host computer! Don't use random
`.gitlab-ci.yml` files from the Internet unless you understand them fully, it
could be a security risk.

You can run the `register` command multiple times to set up additional Runners -
fuller documentation on the different types of executor and their requirements
can be found [here](https://docs.gitlab.com/runner/executors/).
Each `register` invocation adds a section to the configuration file, so make
sure you're referencing the same one each time.

Finally, run `gitlab-runner --log-level debug run --config <path-to-gdk>/gitlab-runner-config.toml`
to get a long-lived Runner process, using the configuration you created in the
last step. It will stay in the foreground, outputting logs as it executes
builds, so run it in its own terminal session.

The Runners pane in the administration panel will now list the Runners. Create a
project in the GitLab web interface and add a
[.gitlab-ci.yml](https://docs.gitlab.com/ce/ci/examples/) file,
or clone an [example project](https://gitlab.com/groups/gitlab-examples), and
watch as the Runner processes the builds just as it would on a "real" install!
