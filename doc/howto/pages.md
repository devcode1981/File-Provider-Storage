# Pages

GDK features an HTTP-only gitlab pages daemon on port `3010`.

In order to handle wildcard hostnames, pages integration relies on [xip.io](https://xip.io) and will not work on a disconnected system.

Port number can be customized editing `gitlab_pages_port` as explained in [using custom ports](configuration.md#using-custom-ports).
