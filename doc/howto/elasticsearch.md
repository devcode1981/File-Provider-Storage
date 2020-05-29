# Elasticsearch

GitLab Enterprise Edition has Elasticsearch integration. In this
document we explain how to set this up in your development
environment.

## Installation

### Install OpenJDK 8 (Elasticsearch dependency)

- You can get a prebuilt OpenJDK Binary for free from [AdoptOpenJDK](https://adoptopenjdk.net).
- You can also install OpenJDK using [Homebrew](https://github.com/AdoptOpenJDK/homebrew-openjdk):

  ```shell
  brew tap AdoptOpenJDK/openjdk
  brew cask install adoptopenjdk8
  ```

### Enable Elasticsearch in the GDK

The default version of Elasticsearch is automatically downloaded into your GDK root under `/elasticsearch`.

To enable the service and make it run as part of `gdk start`:

1. Add these lines to your [`gdk.yml`](../configuration.md):

   ```yaml
   elasticsearch:
     enabled: true
   ```

1. Run `gdk reconfigure`.
1. Uncomment the `elasticsearch:` service in your `Procfile` file.

### Using other Elasticsearch versions

The default Elasticsearch version is defined in [`lib/gdk/config.rb`](../../lib/gdk/config.rb).

To use a different version:

1. Add the `version` and `checksum` keys to your [`gdk.yml`](../configuration.md):

   ```yaml
   elasticsearch:
     enabled: true
     version: 6.5.1
     checksum: 5903e1913a7c96aad96a8227517c40490825f672
   ```

1. Delete your existing Elasticsearch installation (this will also remove all data):

   ```shell
   rm -r elasticsearch
   ```

1. Install the selected version:

   ```shell
   make elasticsearch-setup
   ```

**Note:** Starting with Elasticsearch 7.x, the download URLs have a different format which is not supported by our `Makefile` yet,
see [this issue](https://gitlab.com/gitlab-org/gitlab-development-kit/-/issues/824).

## Setup

1. Go to **Admin Area > License** and ensure you have a [license](https://about.gitlab.com/handbook/developer-onboarding/#working-on-gitlab-ee) installed as this is required for Elasticsearch.

1. Start Elasticsearch by either running `elasticsearch` in a new terminal, or
   by starting the GDK service:

   ```shell
   gdk start elasticsearch
   ```

1. Perform a manual update of the Elasticsearch indexes:

   ```shell
   cd gitlab && bundle exec rake gitlab:elastic:index
   ```

1. Go to **Admin Area > Settings > Integrations** to enable Elasticsearch.

## Tips and Tricks

### Query log

To enable logging for all queries against Elasticsearch you can change the slow
log settings to log every query. To do this you need to send a request to
Elasticsearch to change the settings for the `gitlab-development` index:

```shell
curl -H 'Content-Type: application/json' -XPUT 'http://localhost:9200/gitlab-development/_settings' -d '{
"index.indexing.slowlog.threshold.index.debug" : "0s",
"index.search.slowlog.threshold.fetch.debug" : "0s",
"index.search.slowlog.threshold.query.debug" : "0s"
}'
```

After this you can see every query by tailing the logs from you GDK root:

```shell
tail -f elasticsearch/logs/elasticsearch_index_search_slowlog.log
```
