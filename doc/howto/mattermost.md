# Mattermost

From the GDK directory, create [a `gdk.yml` configuration file](../configuration.md)
containing the following settings:

```yaml
mattermost:
  enabled: true
```

Then you just have to re-generate your Procfile by reconfiguring:

```shell
gdk reconfigure
```

With [Auto DevOps enabled](auto_devops.md), Mattermost will also be served over HTTPS through your QA tunnel.
