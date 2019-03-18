# Registry

If you want to enable Docker registry support you must first
install [docker](https://www.docker.com/#/developers).

In order to enable the registry you have to write `true` in `registry_enabled`
file and reconfigure your `gdk` installation.

```bash
echo true > registry_enabled
gdk reconfigure
```

Registry port defaults to `5000` but it can be changed writing the desired value
in `registry_port`.
Changing either registry or GitLab port number requires `gdk reconfigure`.
