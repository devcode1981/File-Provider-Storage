# Docker Registry replication

## How it works

On every push of new Docker image, GitLab creates a special Geo event that is
propagated to secondary nodes. On the secondary node, there is a specialized
worker called `Geo::ContainerRepositoryServiceWorker` that will fetch the
image from primary node.

## How to set up

Docker Registry replication can be configured in GDK.

Follow steps below to enable it on your local machine. These instructions assume
that you have two Geo nodes (a primary and a secondary) on your local machine. If not, follow [GitLab Geo](geo.md) instructions to set them up.

### Enable Docker Registry on both nodes

To enable Docker Registry on both nodes, follow [Docker Registry](registry.md).

### Enable notification on primary's Registry

Add the following lines to `registry/config.yml` of your primary node:

```
notifications:
  endpoints:
    - name: geo_event
      url: http://docker.for.mac.localhost:3001/api/v4/container_registry_event/events
      headers:
        Authorization: [Bearer <secret>]
      timeout: 500ms
      threshold: 5
      backoff: 1s

```

where `secret` is a secret word that will be used for communication between Registry and
the primary node.

This assumes that your primary node is running on `3001` port of your localhost.
We also assume that you use Mac OS, if you use Linux, instead of `docker.for.mac.localhost`,
use `host.docker.internal`.

### Configure the primary node

Add the secret from the Registry configuration above to `config/gitlab.yml`:

```yaml
registry:
  notification_secret: <secret>
```

### Install certificates on the secondary node

Copy `localhost.crt` and `localhost.key` from your primary node to
the secondary node.

### Restart

Please restart both nodes.
