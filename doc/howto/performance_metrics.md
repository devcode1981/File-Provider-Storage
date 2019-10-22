# Performance metrics for GitLab

GitLab comes with a built-in performance metrics system. Metrics are
collected by InfluxDB and visualized using Grafana.

To use performance metrics in GitLab Development Kit you need a working
Golang compiler (at least v1.7) and NPM installed. InfluxDB and Grafana consume
about 700MB of additional disk space (excluding metrics data).

You need to have a working GDK installation before you install InfluxDB
and Grafana.

First make sure you do not have `gdk run` active anywhere. Then run:

    rm Procfile
    make performance-metrics-setup

This will download and compile InfluxDB and Grafana from source; this
takes a while.

Next, go to http://localhost:3000/admin/application_settings/metrics_and_profiling , look for
the 'Metrics' section, and select 'Enable InfluxDB metrics'. InfluxDB is
using the default host and port (localhost:8089).

After that, you have to run `gdk restart` to start sending metrics to
InfluxDB.

You can access Grafana at http://localhost:9999 using the credentials
`admin` / `admin`.

## Caveats

InfluxDB uses several UDP and TCP ports in the 8080-8090 range. We set
as many ports as possible to only listen on localhost but the cluster
auto-discovery mechanism insists on binding to 0.0.0.0.

It is currently not possible to have two separate GDK installations
running on the same host (e.g. one for GitLab CE, one for GitLab EE) and
enable InfluxDB+Grafana on both.
