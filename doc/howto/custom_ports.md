# Custom ports

You may want to customize the ports in which services runs at, so they can
coexist and be accessible when running multiple GDKs at the same time.

This may also be necessary when simulating some HA behavior or to run Geo.

Most of the time you want to use just the UNIX sockets, but there are situations
where sockets are not supported (for example when using some Java-based IDEs).

## List of port files

Below is a list of all possible/existing port files and the service they are
related to:

| Port file           | Service name                                  |
| ------------------- | --------------------------------------------- |
| port                | unicorn (rails)                               |
| webpack_port        | webpack-dev-server                            |
| postgresql_port     | main postgresql server                        |
| postgresql_geo_port | postgresql server for tracking database (Geo) |
| registry_port       | docker registry server                        | 

## Using custom ports

To use a custom port, configure the service to listen to TCP and/or change the
port you want to use and create the port file with just the port as the content.
