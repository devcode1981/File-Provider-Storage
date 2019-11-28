# Elasticsearch

GitLab Enterprise Edition has Elasticsearch integration. In this
document we explain how to set this up in your development
environment.

## Installation

1. Install OpenJDK 8 (Elasticsearch dependency)

    - You can get a prebuilt OpenJDK Binary for free from [AdoptOpenJDK](https://adoptopenjdk.net)
    - You can also install OpenJDK using [Homebrew](https://github.com/AdoptOpenJDK/homebrew-openjdk)
    ```
    brew tap AdoptOpenJDK/openjdk
    brew cask install adoptopenjdk8
    ```

1. Enable Elasticsearch in the GDK

   The correct version of Elasticsearch should already be installed into your GDK root under `/elasticsearch`.

   To make the service run as part of `gdk start`:

   1. Add these lines to your [`gdk.yml`](configuration.md):

      ```yaml
      elasticsearch:
        enabled: true
      ```

   1. Run `gdk reconfigure`

## Setup

1. Go to **Admin Area > License** and ensure you have a [license](https://about.gitlab.com/handbook/developer-onboarding/#working-on-gitlab-ee) installed as this is required for Elasticsearch.

1. Go to **Admin Area > Settings > Integrations** to enable Elasticsearch.

1. Start Elasticsearch by either running `elasticsearch` in a new terminal, or
   by starting the GDK service:

   ```sh
   gdk start elasticsearch
   ```

1. Perform a manual update of the Elasticsearch indexes:

   ```sh
   cd gitlab && bundle exec rake gitlab:elastic:index
   ```

## Tips and Tricks

### Query log

To enable logging for all queries against Elasticsearch you can change the slow
log settings to log every query. To do this you need to send a request to
Elasticsearch to change the settings for the `gitlab-development` index:

```sh
curl -H 'Content-Type: application/json' -XPUT 'http://localhost:9200/gitlab-development/_settings' -d '{
"index.indexing.slowlog.threshold.index.debug" : "0s",
"index.search.slowlog.threshold.fetch.debug" : "0s",
"index.search.slowlog.threshold.query.debug" : "0s"
}'
```

After this you can see every query by tailing the logs from you GDK root:

```sh
tail -f elasticsearch/logs/elasticsearch_index_search_slowlog.log
```
