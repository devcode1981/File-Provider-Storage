# Registry

## Warning

This document describes how to set up an [Insecure Local Docker Registry](https://docs.docker.com/registry/insecure/) by removing authentication from the registry.  It should only be used for development purposes on your local machine.

## Prerequisites

1. Install either
    * [Docker Desktop on Mac](https://www.docker.com/products/docker-desktop) or
    * [Docker Machine](https://docs.docker.com/machine/install-machine/)
1. Ensure you have a [docker executor runner](https://docs.gitlab.com/runner/executors/docker.html) configured and enabled

## IP address configuration

Throughout this document, we'll assume that the IP address of your desktop machine is `your.local.ip`. You'll need to change this value to match your actual IP address. If you're using `docker-machine`, you'll need to replace this IP address with the one returned from the `docker-machine ip default` command. For details on how to determine whether you're using `docker-machine` and how to switch between `docker-machine` and `docker-desktop-for-mac`, please see the section [Switching Between docker-desktop-on-mac and docker-machine](#switching-between-docker-desktop-on-mac-and-docker-machine).

You may prefer to add an entry to the `/etc/hosts` file on your local machine, changing the IP address to match your local IP address:

```
# in /etc/hosts
your.ip.address gitlab.local
```

This will allow you to use `gitlab.local` instead of your actual IP address in configuration files.

## Enabling the GitLab Local Container Registry

1. Write `true` in the `registry_enabled` file

      ```bash
      echo true > registry_enabled
      gdk reconfigure
      ```
1. Generate a private `rsa:2048` key in the root of the `gdk` project

      ```bash
      openssl req -nodes -newkey rsa:2048 -keyout localhost.key -subj "/CN=gitlab-issuer"
      ```
1. Uncomment the [registry block](https://gitlab.com/gitlab-org/gitlab/blob/6f1bf83acdb68dc7eb2d83ec59c53ed5069b6a8e/config/gitlab.yml.example#L430-438) from your `gdk/gitlab/config/gitlab.yml` file

      ```yaml
      registry:
        enabled: true
        host: your.local.ip
        port: 5000
        api_url: http://your.local.ip:5000
        key: ../localhost.key
        path: ../registry/storage/
        issuer: gitlab-issuer
      ```
1. Copy the [registry/config.yml.example](https://gitlab.com/gitlab-org/gitlab-development-kit/blob/932ba8f6bf0dc69634ac478f5bc9d3bdc213dff7/registry/config.yml.example) file to `gdk/gitlab/registry/config.yml`, and make sure to **remove or comment out** the [auth block](https://gitlab.com/gitlab-org/gitlab-development-kit/blob/932ba8f6bf0dc69634ac478f5bc9d3bdc213dff7/registry/config.yml.example#L26-32) from the file
      ```yaml
      version: 0.1
      <snip>
      health:
        storagedriver:
          enabled: true
          interval: 10s
          threshold: 3
      #auth:
      #  token:
      #    realm: http://127.0.0.1:3000/jwt/auth
      #    service: container_registry
      #    issuer: gitlab-issuer
      #    rootcertbundle: /root/certs/certbundle
      #    autoredirect: false
      validation:
        disabled: true
      ```

1. At this point, you can execute `gdk start` and a local container registry should now be running:

   * Docker shows no running registry

     ```bash
     docker ps

     CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS              PORTS               NAMES
     ```

   * Execute `gdk start`, notice the registry process has been started and the pid value is displayed:

     ```bash
     ok: run: ./services/registry: (pid 36343) 0s, normally down
     ```

   * Execute `gdk tail` and notice the `registry` entries in the log output

     ```bash
     gdk start

     <snip>
     registry   : level=warning msg="No HTTP secret provided - generated random secret ...
     registry   : level=info msg="redis not configured" go.version=go1.11.2 ...
     registry   : level=info msg="Starting upload purge in 13m0s" go.version=go1.11.2 ...
     registry   : level=info msg="using inmemory blob descriptor cache" go.version=go1.11.2 ...
     registry   : level=info msg="listening on [::]:5000" go.version=go1.11.2 ...
     <snip>
     ```

   * **Docker now shows running registry**

     ```bash
     docker ps

     CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS                    NAMES
     61b7b150be33        registry:2          "/entrypoint.sh /etc…"   2 minutes ago       Up 2 minutes        0.0.0.0:5000->5000/tcp   priceless_hoover
     ```

1. The local container registry is now running, see
    [Interacting with the GitLab Local Container Registry](#interacting-with-the-gitlab-local-container-registry
    ) for details on interacting with the registry, but as a quick-start, the following should now work:

     ```bash
     curl your.local.ip:5000/v2/_catalog

     {"repositories":[]}
     ```

### Changing the port number of the GitLab Local Container Registry

The registry port defaults to `5000`.  Follow these steps to change it:

1. Write the desired port number to a `registry_port` file in your GDK root:

    ```bash
    echo 5010 > registry_port
    gdk reconfigure
    ```

1. Update the `port` and `api_url` directives in the
    [registry block](https://gitlab.com/gitlab-org/gitlab/blob/6f1bf83acdb68dc7eb2d83ec59c53ed5069b6a8e/config/gitlab.yml.example#L430-438
    ) from your `gdk/gitlab/config/gitlab.yml` file:

    ```yaml
    registry:
      enabled: true
      host: your.local.ip
      # change the port value in the following two directives
      port: 5010
      api_url: http://your.local.ip:5010
      key: ../localhost.key
      path: ../registry/storage/
      issuer: gitlab-issuer
      ```

### Interacting with the GitLab Local Container Registry

* #### Using the Docker Client

  * ##### Build and tag an image

    ```bash
    docker build -t your.local.ip:5000/custom-docker-image .
    ```

  * ##### Push the image to the local registry

    ```bash
    docker push your.local.ip:5000/custom-docker-image
    ```

* #### Using HTTP

  * ##### Retrieve a list of images available in the repository

    ```bash
    curl your.local.ip:5000/v2/_catalog
    ```

    ```json
    {
      "repositories": [
        "secure-group/docker-image-test",
        "secure-group/klar",
        "secure-group/tests/ruby-bundler/master",
        "testing",
        "ubuntu"
      ]
    }
    ```

  * ##### List tags for a specific image

    ```bash
    curl your.local.ip:5000/v2/secure-group/tests/ruby-bundler/master/tags/list
    ```

    ```json
    {
      "tags": [
        "3bf5c8efcd276bf6133ccb787e54b7020a00b99c",
        "ca928571c661c42dbdadc090f4ef78c8f2854dd9",
        "f7182b792a58d282ef3c69c2c6b7a22f78b2e950"
      ], "name": "secure-group/tests/ruby-bundler/master"
    }
    ```

  * ##### Get image manifest

    ```bash
    curl your.local.ip:5000/v2/secure-group/tests/ruby-bundler/master/manifests/3bf5c8efcd276bf6133ccb787e54b7020a00b99c
    ```

    ```json
    {
      "schemaVersion": 1,
      "name": "secure-group/tests/ruby-bundler/master",
      "tag": "3bf5c8efcd276bf6133ccb787e54b7020a00b99c",
      "architecture": "amd64",
      "fsLayers": [
          {
            "blobSum": "sha256:f9b473be28291374820c40f9359f7f1aa014babf44aadb6b3565c84ef70c6bca"
          },
      "..."
    ```

  * ##### Get image layers

    ```bash
    curl -H 'Accept: application/vnd.docker.distribution.manifest.v2+json' your.local.ip:5000/v2/secure-group/tests/ruby-bundler/master/manifests/3bf5c8efcd276bf6133ccb787e54b7020a00b99c
    ```

    ```json
    {
        "schemaVersion": 2,
        "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
        "config": {
          "mediaType": "application/vnd.docker.container.image.v1+json",
          "size": 7682,
          "digest": "sha256:b5c7d3594559132203ca916d26e969f7bf6492d2e80d753db046dff06a5303e6"
        },
        "layers": [
          {
              "mediaType": "application/vnd.docker.image.rootfs.diff.tar.gzip",
              "size": 45342599,
              "digest": "sha256:e79bb959ec00faf01da52437df4fad4537ec669f60455a38ad583ec2b8f00498"
          },
    "..."
    ```

  * #### Get content of image layer

    ```bash
    curl your.local.ip:5000/v2/secure-group/tests/ruby-bundler/master/blobs/sha256:e79bb959ec00faf01da52437df4fad4537ec669f60455a38ad583ec2b8f00498
    ```

## Using a custom Docker image as the main pipeline build image

It's possible to use the local GitLab container registry as the source of the build image in
pipelines.

1. Create a new project called `custom-docker-image` with the following `Dockerfile`:

    ```docker
    FROM alpine
    RUN apk add --no-cache --update curl
    ```

1. Build and tag an image from within the same directory as the `Dockerfile` for the project.

   ```bash
   docker build -t your.local.ip:5000/custom-docker-image .
   ```

1. Push the image to the registry.  (**Note:** see [Configuring the GitLab Docker runner to automatically pull images](#configuring-the-gitlab-docker-runner-to-automatically-pull-images) for the preferred method which doesn't require you to constantly push the image after each change)

   ```bash
   docker push your.local.ip:5000/custom-docker-image
   ```

   **Note:** If the above command returns the following error:

   ```
   Get https://your.local.ip:5000/v2/: http: server gave HTTP response to HTTPS client
   ```

   You'll need to ensure you add `your.local.ip` as an insecure registry for your local Docker installation.  This can be achieved with [Docker Desktop on Mac](https://www.docker.com/products/docker-desktop) by clicking the `Docker` icon in the menubar, then clicking on `Preferences...`. Click on the `Daemon` tab, then the `Basic` tab and add your `your.local.ip:5000` in the `Insecure registries` section, then click on the `Apply & Restart` button.

   See [this note](https://nickjanetakis.com/blog/docker-tip-50-running-an-insecure-docker-registry) for details on how to configure an insecure registry for other operating systems.

   Having said that, you should follow the directions given in the [Configuring the GitLab Docker runner to automatically pull images](#configuring-the-gitlab-docker-runner-to-automatically-pull-images) section to avoid pushing images altogether.

1. Create a `.gitlab-ci.yml` and add it to the the git repository for the project. Configure the `image` directive in the `.gitlab-ci.yml` file to reference the `custom-docker-image` which was tagged and pushed in steps `2.` and `3.` above:

   ```yaml
   image: your.local.ip:5000/custom-docker-image

   stages:
     - test

   custom_docker_image_job:
     allow_failure: false
     script:
       - curl -I httpstat.us/201
   ```

1. The CI job should now pass and will execute the `curl` command which we previously added to our base image:

      ```shell
      # CI job log output
      curl -I httpstat.us/201

      HTTP/1.1 201 Created
      ```

### Configuring the GitLab Docker runner to automatically pull images

In order to avoid having to push the Docker image after every change, it's
possible to configure the Gitlab Runner to automatically pull the image
if it isn't present. This can be done by setting `pull_policy = "if-not-present"`
in the Runner's config.

```toml
# ~/.gitlab-runner/config.toml

[[runners]]
  name = "docker-executor"
  url = "http://your.local.ip:3001/"
  token = "<my-token>"
  executor = "docker"
  [runners.custom_build_dir]
  [runners.docker]
    image = "ruby:2.6.3"
    privileged = true
    # When the if-not-present pull policy is used, the Runner will first check if the image is present locally.
    # If it is, then the local version of image will be used. Otherwise, the Runner will try to pull the image.
    pull_policy = "if-not-present"
```

## Building and pushing images to your local GitLab container registry in a build step

It's sometimes necessary to use the local GitLab container registry in a pipeline. For
example, the [container scanning](https://docs.gitlab.com/ee/user/application_security/container_scanning/#example)
feature requires a build step that builds and pushes a Docker image to the registry before it can analyze the image.

To add a custom `build` step as part of a pipeline for use in later jobs
such as container scanning, add the following to your `.gitlab-yml.ci`:

```yaml
image: docker:stable

services:
  - name: docker:stable-dind
    command: ["--insecure-registry=your.local.ip:5000"]

stages:
  - build

build:
  stage: build
  variables:
    DOCKER_TLS_CERTDIR: ""
  script:
    - docker pull $CI_REGISTRY_IMAGE/$CI_COMMIT_REF_SLUG:$CI_COMMIT_SHA || true
    - docker build -t $CI_REGISTRY_IMAGE/$CI_COMMIT_REF_SLUG:$CI_COMMIT_SHA .
    - docker push $CI_REGISTRY_IMAGE/$CI_COMMIT_REF_SLUG:$CI_COMMIT_SHA
```

To verify that the build stage has successfully pushed an image to your local GitLab container registry, follow the instructions in the section [List tags for a specific image](#list-tags-for-a-specific-image)

**Some notes about the above `.gitlab-yml.ci` configuration file:**

* The variable `DOCKER_TLS_CERTDIR: ""` is required in the `build` stage because of a breaking change introduced by Docker 19.03, described [here](https://about.gitlab.com/2019/07/31/docker-in-docker-with-docker-19-dot-03/)
* It's necessary to set `--insecure-registry=your.local.ip:5000` for the `docker:stable-dind` service because the `docker` client is expecting our registry to be running over `HTTPS`, however, since we removed the `auth` block back in step `4.` of [Enabling the GitLab Local Container Registry](#enabling-the-gitlab-local-container-registry), we're now running an [insecure-registry](https://docs.docker.com/registry/insecure/) over `HTTP`, which means we need to configure the `docker` service to allow `HTTP` access.

## Running container scanning on a local docker image created by a build step in your pipeline

It's possible to use a `build` step to create a custom docker image and then execute a [container scan](https://gitlab.com/gitlab-org/security-products/analyzers/klar) against this newly built docker image.  This can be achieved by using the following `.gitlab-ci.yml`:

```yaml
# in .gitlab-ci.yml
include:
  template: Container-Scanning.gitlab-ci.yml

image: docker:stable

services:
  - name: docker:stable-dind
    command: ["--insecure-registry=your.local.ip:5000"]

stages:
  - build
  - test

build:
  stage: build
  variables:
    DOCKER_TLS_CERTDIR: ""
  script:
    - docker pull $CI_REGISTRY_IMAGE/$CI_COMMIT_REF_SLUG:$CI_COMMIT_SHA || true
    - docker build -t $CI_REGISTRY_IMAGE/$CI_COMMIT_REF_SLUG:$CI_COMMIT_SHA .
    - docker push $CI_REGISTRY_IMAGE/$CI_COMMIT_REF_SLUG:$CI_COMMIT_SHA

container_scanning:
  stage: test
  variables:
    REGISTRY_INSECURE: "true"
```

**Note:** It's necessary to set `REGISTRY_INSECURE: "true"` in the `container_scanning` job because the [container scanning tool](https://gitlab.com/gitlab-org/security-products/analyzers/klar/) uses [klar](https://github.com/optiopay/klar) under the hood, and `klar` will attempt to fetch the image from our registry using `HTTPS`, meanwhile our registry is running insecurely over `HTTP`.  Setting the `REGISTRY_INSECURE` flag of klar, documented in the klar repo [here](https://github.com/optiopay/klar#usage) and also in the GitLab container scanning repo [here](https://gitlab.com/gitlab-org/security-products/analyzers/klar/#environment-variables) will force the `klar` tool to use `HTTP` when fetching the container image from our insecure registry.

## Switching Between `docker-desktop-on-mac` and `docker-machine`

To determine if you're using `docker-machine`, execute the following command:

```bash
export | grep -i docker

DOCKER_CERT_PATH=~/.docker/machine/machines/default
DOCKER_HOST=tcp://192.168.99.100:2376
DOCKER_MACHINE_NAME=default
DOCKER_TLS_VERIFY=1
```

If a list of environment variables are returned as above, this means that you're currently using `docker-machine` and any `docker` commands will be routed to the virtual machine controlled by `docker-machine`.

To switch from `docker-machine` to `docker-desktop-for-mac`, simply unset the above environment variables:

```bash
unset DOCKER_CERT_PATH DOCKER_HOST DOCKER_MACHINE_NAME DOCKER_TLS_VERIFY
```

## Using a Development Image of the Container Registry

To test development versions of the container registry against GDK:

1. Within the [container registry](https://gitlab.com/gitlab-org/container-registry) project root, build and tag an image that includes your changes:
   ```bash
   docker build -t registry:dev .
   ```

1. Write the image tag in the `registry_image` file and reconfigure GDK:

   ```bash
   echo registry:dev > registry_image
   gdk reconfigure
   ```

1. Restart GDK:

   ```bash
   gdk restart
   ```

1. Inspect docker to confirm that the development image of the registry is running locally:

   ```bash
   docker ps
   CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS               NAMES
   bc6c0efa5582        registry:dev        "registry serve /etc…"   7 seconds ago       Up 6 seconds                            romantic_nash
   ```
