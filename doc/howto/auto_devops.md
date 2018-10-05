# Auto DevOps

This document will instruct you to set up a working GitLab instance with
the ability to run the full Auto DevOps workflow.

## Prerequisites (For GitLab employees only)

IMPORTANT: These steps are currently only applicable to GitLab employees as it
depends on our infrastructure. For non-GitLab employees you can see
[Alternatives](#alternatives) below.

1. Request the required IAM permissions on GCP by [creating an issue in the
   infrastructure
   project](https://gitlab.com/gitlab-com/infrastructure/issues/new) and asking
   for `roles/container.admin` role for `gitlab-internal-153318` GCP project.
   You will also need to provide them with your email address.

1. Get access to [the SSH tunnel
   VM](https://gitlab.com/gitlab-com/infrastructure/issues/4298). You
   will need to request an account for this by [creating an issue in the
   infrastructure
   project](https://gitlab.com/gitlab-com/infrastructure/issues/new) and
   provide them with your SSH public key.

1. Once your account has been created, configure your SSH config `~/.ssh/config` to set the correct username.

    ```
    Host qa-tunnel.gitlab.info
      User <username>
    ```

1. Verify you have `ssh` access into `qa-tunnel.gitlab.info`:

    ```bash
   ssh qa-tunnel.gitlab.info
   > Welcome to Ubuntu 16.04.4 LTS (GNU/Linux 4.13.0-1019-gcp x86_64)
   ```

   If you're able to log in, it means you can move on to the next step.

1. Set up the GDK for your workstation following [the preparation
   instructions](../prepare.md) and [setup instructions](../set-up-gdk.md)

NOTE: Running Auto DevOps flow [downloads/uploads gigabytes of data on each
run](#massive-bandwidth-used-by-auto-devops). For this reason it is not a good
idea to run on 4G and is recommended you run on a cloud VM in GCP so that
everything stays in Google's network so it runs much faster.

## Setup

IMPORTANT: These steps are currently only applicable to GitLab employees as it
depends on our infrastructure. For non-GitLab employees you can see
[Alternatives](#alternatives) below.

Pick two random numbers between 20000 and 29999. These will be used as your subdomain for
your internet-facing URLs for GitLab and the registry so we choose randomly to avoid
conflicts. The following steps assuming your numbers are `1337` for
GitLab and
`1338` for the registry so you need to change those to your chosen numbers.

Using your chosen numbers, you will need to reconfigure GDK. From the
GDK directory, run:

```
echo 1337.qa-tunnel.gitlab.info > hostname
echo 443 > port
echo true > https_enabled
echo true > registry_enabled
echo 1338.qa-tunnel.gitlab.info > registry_host
echo 443 > registry_external_port
gdk reconfigure
```

There are currently two files, `Procfile` and `registry/config.xml` which
we need to manually edit as we don't have support to automatically
add the required settings below using `gdk reconfigure`.

Firstly, add the following lines to the end of `Procfile`:

```yml
tunnel_gitlab: ssh -N -R 1337:localhost:$port qa-tunnel.gitlab.info
tunnel_registry: ssh -N -R 1338:localhost:5000 qa-tunnel.gitlab.info
```

Then edit `registry/config.yml` like so:

```yml
  auth:
    token:
      realm: https://1337.qa-tunnel.gitlab.info/jwt/auth
```

Then start with:

```
port=8080 gdk run
```

Now you should be able to view your internet accessible application at
1337.qa-tunnel.gitlab.info

Now login as root using the default password and change your password.

IMPORTANT: You should change your root password since it is now internet
accessible.

## Google OAuth2

To be able to create a new GKE Cluster via GitLab, you need to configure
Gitlab to be able to authenticate with Google. See the [Google Oauth2
howto](/doc/howto/google-oauth2.md) for instructions.

## Conclusion

With this configuration you will have an internet-accessible
GitLab and registry, so with a valid SSL cert (terminated in the
tunnel server) you should be able to run the full Auto DevOps
flow.

## Running The Auto DevOps Integration Tests

Since you may want to save yourself the hassle of manually setting up a whole
project for Auto DevOps and validating everything works every time you make a
change you can just run [the QA
spec](https://gitlab.com/gitlab-org/gitlab-ce/blob/master/qa/qa/specs/features/browser_ui/7_configure/auto_devops/create_project_with_auto_devops_spec.rb).

### Install gcloud and kubectl

Before you can run the spec, you will need `gcloud` and `kubectl`
installed.

Follow the instructions at https://cloud.google.com/sdk/docs/quickstarts
for the operating system that you are using to install `gcloud`.
Alternatively, if you are using Homebrew on MacOS, you can install
`gcloud` with :

```
brew cask install google-cloud-sdk
```

After you have installed `gcloud`, run the
[init](https://cloud.google.com/sdk/docs/quickstart-macos#initialize_the_sdk) step :

```
gcloud init
```

This init command will help you setup your default zone and project. It will
also prompt you to log in with your Google account.

```
To continue, you must log in. Would you like to log in (Y/n)? Y
```

After you have logged in, select your default project and zone.
GitLabbers, please refer to the handbook for details on which [GCP
project to use](https://about.gitlab.com/handbook/engineering/#google-cloud-platform-gcp).

Next, install `kubectl` as a component of `gcloud` :

```
gcloud components install kubectl
```

NOTE: If you have installed `gcloud` via Homebrew Cask, as described
above, you need to add the following lines in your `~/.bash_profile`
to set the correct PATH to be able to run the `kubectl` binary.

```
  # Add to ~/.bash_profile
  source '/usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/path.bash.inc'
  source '/usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/completion.bash.inc'
```

Make sure to close and reopen your terminal after making these changes.

### Run the integration test

You should now be ready to run the test :

```
cd qa
GITLAB_PASSWORD=<root-user-password> GCLOUD_ZONE=us-central1-a CHROME_HEADLESS=false bin/qa Test::Integration::Kubernetes https://1337.qa-tunnel.gitlab.info/
```

TIP: Consider adding `require 'pry'; binding.pry` breakpoint before [the last
assertion about
builds](https://gitlab.com/gitlab-org/gitlab-ce/blob/eb146e9abe08c3991b5a54237c24d15312c70ee8/qa/qa/specs/features/browser_ui/7_configure/auto_devops/create_project_with_auto_devops_spec.rb#L61)
to save yourself from setting up a full working Auto DevOps project.

NOTE: This test will run as the default project ID. To set or override
the project ID, set `CLOUDSDK_CORE_PROJECT=<gcloud-project-id>`.

NOTE: The GCP account you are using for `gcloud` will require the
`roles/container.admin` for the given GCP project in order for the tests to
succeed.

NOTE: [This
test](https://gitlab.com/gitlab-org/gitlab-ce/blob/eb146e9abe08c3991b5a54237c24d15312c70ee8/qa/qa/specs/features/browser_ui/7_configure/auto_devops/create_project_with_auto_devops_spec.rb#L9)
does teardown the K8s cluster at the end so after the test finishes it won't be
possible to run the pipeline again unless you comment this out.

NOTE: There are other ways of running the QA specs that are documented in the
[gitlab-qa project](https://gitlab.com/gitlab-org/gitlab-qa) but using the
above approach is recommended as it will allow you to debug and iterate on the
spec without rebuilding any docker images and since the above command runs the
spec in your environment rather than in docker it requires less configuration
as it inherits your `gcloud` credentials.

## Technical Details and Alternatives

There are many ways to test out Auto DevOps and we have outlined hopefully one
of the straightforward approaches here.

### Constraints

#### Registry Must Be Routable

Auto DevOps will "deploy" your application to a K8s cluster but the way
this works in K8s is that the cluster actually needs to
download the image from your docker registry running on your machine. Put
another way the K8s cluster needs access over HTTPS to the registry running
on your machine. And HTTPS is necessary as K8s won't download insecure images
by default.

#### GKE K8s cluster is outside of your network

You will likely want to run K8s clusters on GKE as this allows us to test our
GCP integrations as well. You can use minikube too but there are limitations
with this as minikube won't test our GCP integration and minikube does not
simulate a real cluser (eg. internet-facing load balancers with external IP
address are not possible). So when you do choose GKE you conclude that your
registry running on your machine needs to be internet accessible since GKE
is outside your network.

#### Runner on K8s cluster is outside of your network

Assuming that you choose to run the K8s cluster on GKE you may also wish to use
the [1 click
install](https://docs.gitlab.com/ee/user/project/clusters/#installing-applications)
to install the Runner on this cluster. This will mean that in addition to the
registry (which is a separate server on your machine) you will also need the
GitLab instance to be internet accessible because now the runner is not on your
network.

#### Massive bandwidth used by Auto DevOps

Running [the Auto DevOps
pipeline](https://gitlab.com/gitlab-org/gitlab-ce/blob/master/vendor/gitlab-ci-yml/Auto-DevOps.gitlab-ci.yml)
uses a lot of bandwidth doing the following with docker images:

- Runner downloads images from docker hub
- Runner pushes images to the registry
- K8s downloads images from the registry

These docker images tend to be in the order of 400MB-1GB and the pipeline is
not really well optimized for caching. So you will find that if you have a slow
network you really won't be able to run these pipelines at all because it will
take hours to complete. Even if you do have a fast connection you're still
looking at around 20 mins to complete a single run. To speed things up
dramatically you can run everything on a VM on GCP. This will ensure that all
data is staying inside Google's network and things move a lot faster.

### Alternatives

#### Configure A Reverse Proxy In Front Of Your GDK Manually

If you want you can just manually configure a reverse proxy in front of your
GDK instance that does SSL termination for you. A good approach to this would
be to use nginx for SSL termination on a VM with a static IP address. It is
also necessary to have a different external hostname for the container registry
so your reverse proxy will need to virtual hosts configured and both will need
SSL termination.

You will need to replace `<gitlab-hostname>` and `<registry-hostname>` below
with the appropriate values from your reverse proxy settings and run the
following commmands:

```
echo <gitlab-hostname> > hostname
echo 443 > port
echo true > https_enabled
echo true > registry_enabled
echo <registry-hostname> > registry_host
echo 443 > registry_external_port
gdk reconfigure
```

You will need to replace `<gitlab-hostname>` below with the appropriate values
from your reverse proxy settings and edit `registry/config.yml` like so:

```yml
  auth:
    token:
      realm: https://<gitlab-hostname>/jwt/auth
```

NOTE: You should ensure your nginx (or other proxy) is configured to allow up
to 1GB files transferred since the docker images uploaded and downloaded
can be quite large.

#### Why can't we use ngrok or localtunnel?

In theory both of these tools accomplish what we need which is exposing our
local running GitLab instance to the internet.  However, both of these
services, at least in their hosted forms, place limitations on the number of
open connections and the max size of files being uploaded. As such neither of
them, even in the paid plans, will work with proxying the `docker pull` and
`docker push` commands to the container registry.

#### Test changes to `Auto-DevOps.gitlab-ci.yml` on GitLab.com

If you are only changing `Auto-DevOps.gitlab-ci.yml` then you will be
able to just copy and paste this into a `.gitlab-ci.yml` on a project on
GitLab.com to test it out. This won't work if you're also testing this
with corresponding changes to code.

#### Use some seed data for viewing stuff in the UI

At the moment we don't have anything seeded for Kubernetes integrations
or Auto DevOps projects. If we had some seeds for the following tables it
may help if you are only working on the frontend under some limited
circumstances:

- clusters
- clusters_applications_helm
- clusters_applications_ingress
- clusters_applications_prometheus
- clusters_applications_runners
- clusters_applications_jupyter
