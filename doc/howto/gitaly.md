# Gitaly

GitLab uses [Gitaly](https://gitlab.com/gitlab-org/gitaly) to abstract all Git calls. To work on local changes to `gitaly`, please refer to the [Beginner's guide to Gitaly contributions](https://gitlab.com/gitlab-org/gitaly/blob/master/doc/beginners_guide.md).

## Praefect Options

By default, GDK is set up to talk to praefect as a proxy to gitaly. To disable praefect, use the `enabled` field under `praefect` in `gdk.yml`:

```yml
praefect:
  enabled: false
```

### Praefect Virtual Storages

If you need to work with multiple storages in GitLab, you can create a second
virtual storage in Praefect. You'll need at least one more Gitaly service or
storage to create another virtual storage.

#### Adding More Gitaly Nodes

**TODO**: [Automate this process](https://gitlab.com/gitlab-org/gitlab-development-kit/-/issues/827)

By default, GDK generates a Praefect configuration containing only one Gitaly.
Follow these steps to add additional backend Gitaly nodes to use in more virtual
storages:

1. Increase this number by editing `gdk.yml`:
   ```yaml
   praefect:
     node_count: 2
   ```
1. Run `gdk reconfigure` to put the change into effect.
1. Edit the Praefect configuration file `gitaly/praefect.config.toml` to add the
   new virtual storage.
   - Before:
     ```toml
     [[virtual_storage]]
     name = 'default'

     [[virtual_storage.node]]
     storage = "praefect-internal-0"
     address = "unix:/Users/paulokstad/gitlab-development-kit/gitaly-praefect-0.socket"
     primary = true

     [[virtual_storage.node]]
     storage = "praefect-internal-1"
     address = "unix:/Users/paulokstad/gitlab-development-kit/gitaly-praefect-1.socket"
     primary = false
     ```
   - After:
     ```toml
     [[virtual_storage]]
     name = 'default'

     [[virtual_storage.node]]
     storage = "praefect-internal-0"
     address = "unix:/Users/paulokstad/gitlab-development-kit/gitaly-praefect-0.socket"
     primary = true

     [[virtual_storage]]
     name = 'default2'

     [[virtual_storage.node]]
     storage = "praefect-internal-1"
     address = "unix:/Users/paulokstad/gitlab-development-kit/gitaly-praefect-1.socket"
     primary = true
     ```
1. Edit `gitlab/config/gitlab.yml` to add the new virtual storage:
   - Before:
     ```yaml
     repositories:
       storages: # You must have at least a `default` storage path.
         default:
           path: /
           gitaly_address: unix:/Users/paulokstad/gitlab-development-kit/praefect.socket
     ```
   - After:
     ```yaml
     repositories:
       storages: # You must have at least a `default` storage path.
         default:
           path: /
           gitaly_address: unix:/Users/paulokstad/gitlab-development-kit/praefect.socket
         default2:
           path: /
           gitaly_address: unix:/Users/paulokstad/gitlab-development-kit/praefect.socket
     ```
1. Restart GDK to allow the new config values to take effect: `gdk restart`
