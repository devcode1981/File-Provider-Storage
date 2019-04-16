# Elasticsearch

GitLab Enterprise Edition has Elasticsearch integration. In this
document we explain how to set this up in your development
environment.

## Installation

1. Install Java 8 (Elasticsearch dependency)

   If needed, install Java 8 (JRE). For macOS you can download it from
https://www.java.com.

1. Uncomment ElasticSearch in your Procfile

   ElasticSearch 6.5.1 should already be installed into your GDK root
under /elasticsearch. Uncomment the `#elasticsearch:` line in your
Procfile to make ElasticSearch run as part of your `gdk run` or `gdk
run db` processes.

## Setup

1. Go to **Admin Area > Settings > Integrations** to enable Elasticsearch.

1. Start Elasticsearch by either running `elasticsearch` in a new terminal, or
   by adding it to your `Procfile`:

   ```
   elasticsearch: elasticsearch
   ```

1. Be sure to restart the GDK's `foreman` instance if it's running.

1. Perform a manual update of the Elasticsearch indexes:

   ```sh
   cd gitlab && bundle exec rake gitlab:elastic:index
   ```
