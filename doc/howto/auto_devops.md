# Auto DevOps

IMPORTANT: These docs are currently for GitLab employees only as it
depends on our infrastructure.

This document will instruct you to set up a working GitLab instance with
the ability to run the full Auto DevOps workflow.

## Prerequisites

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
    Verify that you can now ssh into `qa-tunnel.gitlab.info`.
1. Set up the GDK for your workstation following [the preparation
   instructions](../prepare.md) and [setup instructions](../set-up-gdk.md)

NOTE: Running Auto DevOps flow [downloads/uploads gigabytes of data on each
run](#massive-bandwidth-used-by-auto-devops). For this reason it is not a good
idea to run on 4G and is recommended you run on a cloud VM in GCP so that
everything stays in Google's network so it runs much faster.

## Setup

Pick 2 random numbers in [20000,29999]. These will be used as your subdomain for
your internet-facing URLs for GitLab and the registry so I say random because we don't want them to
conflict. The following steps assuming your numbers are `1337` for
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

Now with this configuration you will have an internet accessible GitLab
and registry so with a valid SSL cert (terminated in the tunnel server)
and you should be able to run the full auto devops flow.

## Running The Auto DevOps Integration Tests

Since you may want to save yourself the hassle of manually setting up a whole
project for Auto DevOps and validating everything works every time you make a
change you can just run [the QA
spec](https://gitlab.com/gitlab-org/gitlab-ce/blob/master/qa/qa/specs/features/project/auto_devops_spec.rb).

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

NOTE: This test will run as the default project ID. To set or override
the project ID, set `CLOUDSDK_CORE_PROJECT=<gcloud-project-id>`.

NOTE: [This
test](https://gitlab.com/gitlab-org/gitlab-ce/blob/master/qa/qa/specs/features/project/auto_devops_spec.rb#L6)
does teardown the K8s cluster at the end so after the test finishes it won't be
possible to run the pipeline again unless you comment this out.

## Troubleshooting

### If you cannot connect to your internet-facing URL

It may be because the port is already taken. In this case you would see:

```
Warning: remote port forwarding failed for listen port
```

in your log.

It may also be because the SSH connection got stuck. I'm not sure how to
stop this from happening but you can fix this by restarting `gdk run`.

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
registry running on your machine needs to be internet accessible since.

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
