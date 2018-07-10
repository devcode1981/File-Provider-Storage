# Object Storage (LFS, Artifacts, etc)

GitLab Enterprise Edition has Object Storage integration. In this
document we explain how to set this up in your development
environment.

In order to take advantage of the GDK integration you must first install
[minio](https://docs.minio.io/docs/minio-quickstart-guide) binary (no docker image).

You can enable the object store writing `true` in `object_store_enabled` file and
reconfiguring your `gdk` installation.

```sh
echo true > object_store_enabled
gdk reconfigure
```

Object store port defaults to `9000` but it can be changed writing the desired value
in `object_store_port`.

Changing port number requires `gdk reconfigure`.

## Creating a new bucket

In order to start using minio from your gitlab instance you have to create buckets first. You can create a new bucket by accessing http://127.0.0.1:9000/ (default configuration).

## Changing GitLab configuration

GitLab local development instace expects `uploads` and `lfs-objects` buckets but you can change them in `gitlab.yml` file. You will also need to change `aws_access_key_id` and `aws_secret_access_key` according to your minio installation (you can see these values when you start minio).
