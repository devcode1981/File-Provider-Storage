# Asset Proxy / Camo Server

GitLab can be configured to use an [asset proxy server](https://docs.gitlab.com/ee/security/asset_proxy)
when requesting external images/videos in issues, comments, etc.  This helps
ensure that malicious images do not expose the user's IP address when they are fetched.

We currently recommend using [cactus/go-camo](https://github.com/cactus/go-camo#how-it-works) as it supports proxying video and is more configurable.

## Installation

A Camo server is used to act as the proxy.

1. Follow the build and installation instructions at [building cactus/go-camo](https://github.com/cactus/go-camo#building).  By the end, from the
   `go-camo` directory, you should be able to

   ```shell
   cd build/bin
   ./go-camo -k "somekey" --allow-content-video -H "Content-Security-Policy: media-src 'self'"
   ```

   and get something like

   ```shell
   time="2019-07-24T14:31:29.988355000-05:00" level="I" msg="Starting server on: 0.0.0.0:8080"
   ```

1. Make sure your instance of GitLab is running, and that you have a private API token created.
   Then issue this from the command line, changing the values as needed:

    ```
    curl --request "PUT" "http://localhost:3000/api/v4/application/settings?\
    asset_proxy_enabled=true&\
    asset_proxy_url=http://localhost:8080&\
    asset_proxy_secret_key=<somekey>" \
    --header 'PRIVATE-TOKEN: <my-private-token>'
    ```

1. Restart the server for the changes to take effect. Each time you change
   any values for the asset proxy, you need to restart the server.


## Usage

Once the Camo server is running and you've enabled the GitLab settings, any image or video that
references an external source will get proxied to the Camo server.

For example, the following is a link to an image in Markdown:

```markdown
![logo](https://about.gitlab.com/images/press/logo/jpg/gitlab-icon-rgb.jpg)
```

The following is an example of a source link that could result:

```
http://localhost:8080/f9dd2b40157757eb82afeedbf1290ffb67a3aeeb/68747470733a2f2f61626f75742e6769746c61622e636f6d2f696d616765732f70726573732f6c6f676f2f6a70672f6769746c61622d69636f6e2d7267622e6a7067
```
