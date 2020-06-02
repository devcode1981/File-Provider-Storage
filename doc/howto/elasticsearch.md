# Elasticsearch

GitLab Enterprise Edition has Elasticsearch integration. In this
document we explain how to set this up in your development
environment.

## Installation

### Enable Elasticsearch in the GDK

The default version of Elasticsearch is automatically downloaded into your GDK root under `/elasticsearch`.

To enable the service and make it run as part of `gdk start`:

1. Add these lines to your [`gdk.yml`](../configuration.md):

   ```yaml
   elasticsearch:
     enabled: true
   ```

1. Run `gdk reconfigure`.

### Using other Elasticsearch versions

#### Version 7

The default Elasticsearch version is defined in [`lib/gdk/config.rb`](../../lib/gdk/config.rb).

For example, to use 7.5.2:

1. Add the `version` and `[linux|mac]_checksum` keys to your [`gdk.yml`](../configuration.md):

   ```yaml
   elasticsearch:
     enabled: true
     version: 7.5.2
     mac_checksum: f3142e73e51a9be25c74cb85dcf2cf20ca8acaf6480be616c4dd0404469e5f22a086efbe81dc975d0af19543437e8daf45d41a5952750048b01517857a00c676
   ```

1. Install the selected version:

   ```shell
   make elasticsearch-setup
   ```

#### Version 6

While GDK does not support installing Elasticsearch version 6.x, it can be easily run with Docker:

```shell
docker run -p 9200:9200 -d docker.elastic.co/elasticsearch/elasticsearch:6.5.1
```

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
