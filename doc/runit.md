# runit process supervision

We have replaced
[Foreman](https://github.com/ddollar/foreman) with [runit](http://smarden.org/runit/).

`gdk run` is no longer available. Instead, use `gdk start`, `gdk stop`,
and `gdk tail`.

## Why replace Foreman

Foreman was the tool behind `gdk run`; it was configured via the
`Procfile`. While Foreman is easy to get started with, we find it has a
number of drawbacks in GDK:

- Foreman is attached to a terminal window. If that terminal window
  gets closed abruptly, Foreman is not able to cleanly shut down the
  processes it was supervising, leaving them running in the
  background. This is a problem because the next time you start
  Foreman, most of its services will fail to start because they need
  resources (network ports) still being used by the old processes that
  never got cleaned up.
- There is no good way to start / stop / restart individual processes
  in the Procfile. This is not so noticeable when you work with Ruby
  or JavaScript because of live code reload features, but for Go
  programs (e.g. `gitaly`) this does not work well. There you really
  need to stop an old binary and start a new binary.

## Why runit

runit is a process supervision system that we also use in
Omnibus-GitLab. Compared to Foreman, it is more of a system
administration tool than a developer tool.

The reason we use runit and not the native OS supervisor (launchd on
macOS, systemd on Linux) is that:

- runit works the same on macOS and Linux so we don't need to handle
  them separately
- runit does not mind running next to the official OS supervisor
- It is easy to run more than one runit supervision tree (e.g. if you
  have multiple GDK installations)

## Solving the closed terminal window problem

runit takes its configuration from a directory tree; in our case this is
`/path/to/gdk/services`. We start a `runsvdir` process
anchored to this directory tree once, and never stop it (until you shut
down your computer).

If you close your terminal window then `runsvdir` and everything under
it will just keep running. If you want to stop GDK after that, just
create a new terminal, `cd` to your GDK installation, and run
`gdk stop`. The `gdk stop` command will talk to `runsvdir` and tell it
to stop your GDK services.

If all goes well you don't have to worry about `runsvdir`; the `gdk`
command will manage it for you.

## Solving the individual restart problem

You can start, stop and restart individual services by specifying them
on the command line. For example: `gdk restart postgresql redis`.

Although `rails` really refers to more than one process, we have created
a shortcut that lets you write e.g. `gdk stop rails` if you want to
reclaim some memory while not using `localhost:3000`.

## Logs

Because runit is not attached to a terminal, the logs of the services
you're running must go to files. If you want to see this logs in your
terminal, like they show up with Foreman, then run `gdk tail`. Note that
unlike with Foreman, if you press Ctrl-C into `gdk tail`, the logs stop,
but the services keep running. Use `gdk stop` if you want to also stop
the services.

You can also look at the logs for a subset of services:
`gdk tail gitaly postgresql` or `gdk tail rails`.

## Modifying service configuration

To modify the actual commands used to start services, use the `Procfile`
just like with Foreman. Every time you run `gdk start`, `gdk stop` etc.
GDK will update the runit service configuration from the Procfile.

If you want to remove a service `foo`:

- Comment out or delete `foo: exec bar` from Procfile
- Run `gdk stop foo`
- `rm services/foo`

## Modifying environment configuration for services

If you want to set environment variables for services, either edit the
Procfile and restart the service, or create a file `env.runit` in the root directory with contents such as `export myvar=myvalue`.

Example:

```bash
export CUSTOMER_PORTAL_URL=http://localhost:5000
export IS_EE=true
export USE_WEB_SERVER=unicorn
```
