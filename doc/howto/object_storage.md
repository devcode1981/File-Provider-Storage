# Object Storage (LFS, Artifacts, etc)

GitLab has Object Storage integration.
In this document we explain how to set this up in your development
environment.

In order to take advantage of the GDK integration you must first install
[MinIO](https://docs.minio.io/docs/minio-quickstart-guide) binary (no Docker image).

You can enable the object store by adding the following to your `gdk.yml`:

```yaml
object_store:
  enabled: true
  port: 9000
```

The object store port defaults to `9000` but can be changed via the `object_store.port` setting in your `gdk.yml`.

Changing port number requires `gdk reconfigure`.

## MinIO errors

If you cannot start MinIO, you may have an old version not supporting the `--compat` parameter.

`gdk tail minio` will show a crash loop with the following error

```plaintext
Incorrect Usage: flag provided but not defined: -compat
```

Upgrading MinIO to the latest version will fix it.

## Creating a new bucket

In order to start using MinIO from your GitLab instance you have to create buckets first.
You can create a new bucket by accessing <http://127.0.0.1:9000/> (default configuration).
