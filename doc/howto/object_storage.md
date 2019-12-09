# Object Storage (LFS, Artifacts, etc)

GitLab has Object Storage integration.
In this document we explain how to set this up in your development
environment.

In order to take advantage of the GDK integration you must first install
[minio](https://docs.minio.io/docs/minio-quickstart-guide) binary (no docker image).

You can enable the object store by adding the following to your `gdk.yml`:

```
object_store:
  enabled: true
  port: 9000
```

The object store port defaults to `9000` but can be changed via the `object_store.port` setting in your `gdk.yml`.

Changing port number requires `gdk reconfigure`.

## Minio errors

If you cannot start minio, you may have an old version not supporting the `--compat` parameter.

`gdk tail minio` will show a crash loop with the following error

```
Incorrect Usage: flag provided but not defined: -compat
```

Upgrading minio to the latest version will fix it.

## Creating a new bucket

In order to start using minio from your gitlab instance you have to create buckets first.
You can create a new bucket by accessing http://localhost:9000/ (default configuration).
