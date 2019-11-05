# Configuration

This document describes how you can configure your GDK environment.

## Git configuration

Git has features which are disabled by default, and would be great to enable to
be more effective with Git. Run `rake git:configure` to set the recommendations
for some repositories within the GDK.

To set the configuration globally, run `rake git:configure[true]`. When using
`zsh`, don't forget to escape the square brackets: `rake git:configure\[true\]`.

## GDK configuration

There are many configuration options for GDK. GDK can be configured using either:

- [`gdk.yml`](#gdkyml) configuration file.
- [Loose files](#loose-files-deprecated) (deprecated).

### gdk.yml

Placing your settings in `gdk.yml` at the root of GDK is the preferred configuration
method.

To see available configuration settings, see [`gdk.example.yml`](../../gdk.example.yml).

This file contains all possible settings with example values. Note
that these values may not be the default that GDK will use.

If you want to check which settings are in place, you can run `rake
dump_config`, which will print all applied settings in a YAML structure.

#### Notable settings

Here are a few settings worth mentioning:

| Setting                | Default | Description                                                                                |
|------------------------|---------|--------------------------------------------------------------------------------------------|
| `port`                 | `3000`  | Select the port to run GDK on, useful when running multiple GDKs in parallel.              |
| `webpack.port`         | `3808`  | Also useful to configure when running GDKs in parallel.                                    |
| `gitlab_pages.port`    | `3010`  | Specify on which port GitLab Pages should run. See also the [Pages guide](pages.md).       |
| `relative_url_root`    | `/`     | When you want to test GitLab being available on a different path than `/`, e.g. `/gitlab`. |
| `object_store.enabled` | `false` | Set this to `true` to enable Object Storage with MinIO.                                    |
| `registry.enabled`     | `false` | Set this to `true` to enable container registry.                                           |
| `geo.enabled`          | `false` | Set this to `true` to enable Geo (for now it just enables `postgresql-geo` and `geo-cursor` services). |

There are also a few settings that configure the behavior of GDK itself:

| Setting                 | Default | Description                                                                                      |
|-------------------------|---------|--------------------------------------------------------------------------------------------------|
| `gdk.overwrite_changes` | `false` | When set to `true` `gdk reconfigure` will overwrite files and move the old version to `.backups`.|
| `gdk.ignore_foreman`    | `false` | Set this to `true` to ignore any running Foreman processes. Might be useful when you run GDK in parallel with other services that use Foreman. |

### Loose files (deprecated)

Before `gdk.yml` was introduced, GDK could be configured through a
bunch of loose files, where each file sets one setting.

It is still possible to use these loose files, but it's deprecated and
will be removed in the future. A migration path will be provided
when this option is removed.

Below is a table of all the settings that can be set this way:

| Filename                     | Type         | Default                          |
|------------------------------|--------------|----------------------------------|
| `host` / `hostname`          | string or IP | `0.0.0.0`                        |
| `port`                       | number       | `3000`                           |
| `https_enabled`              | boolean      | `false`                          |
| `relative_url_root`          | string       | `/`                              |
| `webpack_host`               | string or IP | `0.0.0.0`                        |
| `webpack_port`               | number       | `3808`                           |
| `registry_enabled`           | boolean      | `false`                          |
| `registry_port`              | number       | `5000`                           |
| `registry_image`             | string       | `registry:2`                     |
| `object_store_enabled`       | boolean      | `false`                          |
| `object_store_port`          | number       | `9000`                           |
| `postgresql_port`            | number       | `5432`                           |
| `postgresql_geo_port`        | number       | `5432`                           |
| `gitlab_pages_port`          | number       | `3010`                           |
| `auto_devops_enabled`        | boolean      | `false`                          |
| `auto_devops_gitlab_port`    | number       | `rand(20000..24999)`             |
| `auto_devops_registry_port`  | number       | `auto_devops_gitlab_port + 5000` |
| `google_oauth_client_secret` | ?            | ?                                |
| `google_oauth_client_id`     | ?            | ?                                |
| `praefect_enabled`           | boolean      | `false`                          |

### Configuration precedence

GDK will use the following order of precedence when selecting the
configuration method to use:

- `gdk.yml`
- Loose file
- Default value

### Reading the configuration

To print settings from the config you can use `gdk config get <setting>`.

More information on the available `gdk` commands is found in
[GDK commands](gdk_commands.md#configuration).

### Implementation detail

Here are some details on how the configuration management is built.

#### GDK::ConfigSettings

This is the base class and the engine behind the configuration
management. It defines a DSL to configure GDK.

Most of the magic happens through the class method
`.method_missing`. The implementation of this method will dynamically
define instance methods for configuration settings.

Below is an example subclass of `GDK::ConfigSettings` to demonstrate
each kind.

```ruby
class ExampleConfig < GDK::ConfigSettings
  foo 'hello'
  bar { rand(1..10) }
  fuz do |f|
    f.buz 1234
  end
end
```

* `foo`: (literal value) This is just a literal value, it can be any
  type (e.g. Number, Boolean, String).
* `bar`: (block without argument) This is using a block to set a
  value. It evaluates the Ruby code to dynamically calculate a value.
* `fuz`: (block with argument) When the block takes a single argument,
  it expects you'll be setting child settings.

If you'd dump this config with `rake dump_config` you'll get something
like:

```yaml
foo: hello
bar: 5
fuz:
  buz: 1234
```

When you use a block without argument you can also calculate a value
based on another setting. So for example, we'd could replace the `bar`
block with `{ config.fuz.buz + 1000 }` and then the value would be
`2234`.

#### GDK::Config

`GDK::Config` is the single source of truth when it comes down to
defaults. In this file, every existing setting is specified and for
each setting a default is provided.

#### Dynamic settings

Some settings in `GDK::Config` are prepended with `__` (double
underscore). These are not supposed to be set in `gdk.yml` and only
act as a intermediate value. They also will not be shown by `#dump!`.

### Adding a setting

When you add a new setting:

1. Add it to `lib/gdk/config.rb`.
1. Run `rake gdk.example.yml` to regenerate this file.
1. Commit both files.
