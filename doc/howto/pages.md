# Pages

GDK features an HTTP-only GitLab Pages daemon on port `3010`.

In order to handle wildcard hostnames, pages integration relies on
[xip.io](https://xip.io) and will not work on a disconnected system.

Port number can be customized editing `gdk.yml` as explained in
[GDK configuration](configuration.md#gdkyml).
