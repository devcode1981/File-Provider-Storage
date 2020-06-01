# Package managers

Set up GDK for specific package managers and package manager configurations.

## GoProxy

The GoProxy client enforces some specific constraints that make it unable to
work with a standard GDK install. It requires an https connection, and also
will make additional requests to port 443 regardless of the port used in the
GOPROXY environment variable.

These steps will allow you to enable your GDK install with HTTPS and also
allow it to respond to requests on port 443.

1. Follow the [NGINX guide](nginx.md) to enable HTTPS. You must include the steps:
   - [Configuring a loopback device](nginx.md#configuring-a-loopback-device-optional).
   - [Update `gdk.yml` for HTTPS](nginx.md#update-gdkyml-for-https-optional).

  Your local GitLab should now be available at <https://gdk.test:3443> and <https://127.1.1.1:3443>

1. Clone the [Super Simple Proxy](https://gitlab.com/firelizzard/super-simple-proxy)
project (authored by the same community contributor that contributed the GoProxy MVC!)

1. Run the proxy with the following command. The `pem` files will be wherever you created
them the previous step.

  ```shell
  go run . -netrc -secure gdk.test:443 -key /path/to/gdk.test-key.pem -cert /path/to/gdk.test.pem -insecure gdk.test:80 -forward gdk.test,gdk.test:3443
  ```

You should now be able to access GitLab at <https://gdk.test> (port 443 is default for HTTPS).

You will also need to prevent Go from making calls to <https://sum.golang.org>
to check the validity of your package (it will not be aware of localhost or your
private packages). Run one of the following commands before you begin using the
Go client to install and work with Go packages. Otherwise, the Go client will
fail to fetch your private packages.

```shell
# entirely disable downloading checksums for all Go modules
export GOSUMDB=off

# disable checksum downloads for all projects
export GONOSUMDB=gdk.test

# disable checksum downloads for projects within a namespace
export GONOSUMDB=gdk.test/namespace

# disable checksum downloads for a specific project
export GONOSUMDB=gdk.test/namepsace/project
```

You now should be able to fully test and work with the GoProxy in your local
GDK instance.
