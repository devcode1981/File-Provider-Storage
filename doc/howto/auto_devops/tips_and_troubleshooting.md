# Auto DevOps - Tips and Troubleshooting

- [Tips](#tips)
- [Troubleshooting](#troubleshooting)

## Tips

### Useful Commands

- Besides this list of tips and troubleshooting, be sure to check out our list of [Useful Commands](./useful_commands.md)

### QA

- Consider adding `require 'pry'; binding.pry` breakpoint before [the last
assertion about
builds](https://gitlab.com/gitlab-org/gitlab-ce/blob/eb146e9abe08c3991b5a54237c24d15312c70ee8/qa/qa/specs/features/browser_ui/7_configure/auto_devops/create_project_with_auto_devops_spec.rb#L61)
to save yourself from setting up a full working Auto DevOps project.

- Set the environment variable `CHROME_REUSE_PROFILE` to `true` which
  will allow QA to re-use the same user profile so that slow files such
  as `main.chunk.js` can be cached in memory.

- Disable source-maps for GDK by setting the environment variable
  `NO_SOURCEMAPS` to `true`. This reduces the size of `main.chunk.js`
  from 11 MB to 4.6 MB, which will help for connections with slow upload speeds.

### Helm/Tiller Communication

- One can run manual Helm commands from your local machine and communicate to our remote Tiller running on GKE. Check our [Useful Commands - Talking to Tiller](./useful_commands.md#talking-to-tiller) to know how to achieve it.

### Configuration for Auto DevOps base domain

Please refer to the [Auto DevOps Base Domain](https://docs.gitlab.com/ee/topics/autodevops/#auto-devops-base-domain) to learn more about it.

## Development using localhost instead

Consider not using the internet-facing URL for non Auto DevOps flows,
but accessing your local GitLab instance via localhost. If you have
followed the [Auto DevOps setup](../auto_devops.md), edit the
`config/gitlab.yml` file to the following:

```yaml
host_settings_auto: &gitlab_auto_devops
  host: <PORT>.qa-tunnel.gitlab.info
  port: 443
  https: true

host_settings_local: &gitlab_localhost
  host: localhost
  port: 80 # Set to 443 if using HTTPS, see installation.md#using-https for additional HTTPS configuration details
  https: false # Set to true if using HTTPS, see installation.md#using-https for additional HTTPS configuration details

production: &base
  #
  # 1. GitLab app settings
  # ==========================

  ## GitLab settings
  gitlab:
    ## Web server settings (note: host is the FQDN, do not include http://)
    # <<: *gitlab_auto_devops
    <<: *gitlab_localhost
```

This way you can switch between using `*gitlab_localhost` for other
development and `*gitlab_auto_devops` for Auto-DevOps development.
Remember to restart your GDK after editing `config/gitlab.yml`.

NOTE: You will have to reapply the edits above after each `gdk
reconfigure`.

## Using an external virtual machine for the development

If you decide to use an external virtual machine to run GDK on it, you might
want to still be able to use your favorite tools and IDE locally.

If you decide to follow this direction it might be a good idea to avoid
uploading your private SSH keys there, in case if you want to push to
GitLab from the virtual machine.

You can use [`unison`](https://www.cis.upenn.edu/~bcpierce/unison/index.html)
to synchronize your local and remote files. Use:

```bash
unison -batch ./gdk ssh://my-account@gcp.vm.example.com
```

You need to install `unison` locally and on the remote machine with

```bash
apt-get install unison
```

`unison` makes it easier to synchronize files bi-directionally, however it does
not happen automatically, you need to invoke the command to trigger the
synchronization.

Some people also use [Mutagen](https://github.com/havoc-io/mutagen) instead of
`unison`, you can also give it a try and choose the solution you prefer.

It is also possible to configure your environment in a way that only local ->
remote synchronization is needed. In this case you can use `lsyncd` tool, which
appears to work reasonably well when bi-directional communication is not
needed.

## Troubleshooting

### The Ingress is never assigned an IP address

If your Ingress is never assigned an IP address and you've waited for the IP address to appear on the cluster page for several minutes, it's quite possible that your GCP project has hit a limit of static IP addresses. See [how to clean up unused load balancers above](../auto_devops.md#unused-load-balancers).

### Error due to `Insufficient regional quota` for `DISKS_TOTAL_GB`

When [creating a new GKE cluster](https://docs.gitlab.com/ee/user/project/clusters/#creating-the-cluster), GKE will create persistent disks for you. If you are
running into the following error:

```
ResponseError: code=403, message=Insufficient regional quota to satisfy request: resource "DISKS_TOTAL_GB"
```

this would indicate you have reached your limit of persistent disks. See [how
to clean up unused persistent disks above](../auto_devops.md#unused-persistent-disks).

### 502 Bad Gateway

There are two known reasons for which you may receive a 502 Bad Gateway response when opening the application using the tunnel URL:

#### SSH requires a passphrase

For GDK to run, it needs to be able to SSH into `qa-tunnel.gitlab.info` without user input. The following steps will allow you to authenticate without entering your passphrase on future logins:

1. Run [`ssh-add`](https://linux.die.net/man/1/ssh-add).
1. Enter your passphrase.

If not set up correctly, expect `502 Bad Gateway` responses when navigating to `<gitlab-number>.qa-tunnel.gitlab.info` and the string `Enter passphrase for key '/Users/username/.ssh/id_rsa'` to pepper the GDK logs.


#### Procfile was not updated properly

After following the steps indicated in the [autodevops guide](../auto_devops.md), the Procfile located in the root of the GDK installation won’t have the tunnel configuration. If the Procfile is correct, you should find these lines:

```bash
# Tunneling
#
tunnel_gitlab: ssh -N -R [PORT]:localhost:$port -o ControlPath=none -o ControlMaster=no qa-tunnel.gitlab.info
tunnel_registry: ssh -N -R [PORT]:localhost:5000 -o ControlPath=none -o ControlMaster=no qa-tunnel.gitlab.info
```

The `tunnel_gitlab` and `tunnel_registry` lines may be commented out. If that’s the case, you can either delete the Procfile file and run `gdk reconfigure` or uncomment those lines and replace `[PORT]` with the ports specified in the `auto_devops_gitlab_port` and `auto_devops_registry_port` files.
