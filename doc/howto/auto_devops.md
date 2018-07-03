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
   provide them with your SSH public key. Once this is done verify that
   you can ssh into `qa-tunnel.gitlab.info`.
1. Create a Debian VM on google cloud and setup the GDK following [the
   preparation instructions for debian](../prepare.md) and [setup instructions](../set-up-gdk.md)
1. 

## Setup

Pick 2 random numbers in [20000,29999]. These will be used as your subdomain for
your internet facing URLs for GitLab and the registry so I say random because we don't want them to
conflict. The following steps assuming your numbers are `1337` for gitlab and
`1338` for the registry so you need to change those to your chosen numbers in the
actual range.

From the GDK directory run:

```
echo true > registry_enabled
echo 1337.qa-tunnel.gitlab.info > hostname
gdk reconfigure
```

After this you need to edit the file `gitlab/config/gitlab.yml` like so:

```yml
  gitlab:
    host: 1337.qa-tunnel.gitlab.info
    port: 443
    https: true
```

Also:

```yml
  registry:
    enabled: true
    host: 1338.qa-tunnel.gitlab.info
    port: 443
```

Then you will need to add the following lines to the end of `Procfile`:

```yml
tunnel_gitlab: ssh -N -R 1337:localhost:3000 qa-tunnel.gitlab.info
tunnel_registry: ssh -N -R 1338:localhost:5000 qa-tunnel.gitlab.info
```

Then edit `config/registry.yml` like so:

```yml
  auth:
    token:
      realm: https://1337.qa-tunnel.gitlab.info/jwt/auth
```

Then start with:

```
gdk run
```

Now you should be able to view your internet accessible application at
1337.qa-tunnel.gitlab.info

Now login as root using the default password and change your password.

IMPORTANT: You should change your root password since it is now internet
accessible.

## Conclusion

Now with this configuration you will have an internet accessible GitLab
and registry so with a valid SSL cert (terminated in the tunnel server)
and you should be able to run the full auto devops flow.

## Troubleshooting

### If you cannot connect to your internet facing URL

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
this works in K8s is that the cluster cluster actually needs to
download the image from your docker registry running on your machine. Put
another way the K8s cluster needs access over HTTPS to the registry running
on your machine. And HTTPS is necessary as K8s won't download insecure images
by default.

#### GKE K8s cluster is outside of your network

You will likely want to run K8s clusters on GKE as this allows us to test our
GCP integrations as well. You can use minikube too but there are limitations
with this as minikube won't test our GCP integration and minikube does not
simulate a real cluser (eg. internet facing load balancers with external IP
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
data is staying inside google's network and things move a lot faster.

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
