# Elasticsearch

GitLab Enterprise Edition has Elasticsearch integration. In this
document we explain how to set this up in your development
environment.

## Installation: OS X

1. Install Elasticsearch with [Homebrew]:

    ```sh
    brew install elasticsearch
    ```

1. Install the `delete-by-query` plugin:

    ```sh
    `brew info elasticsearch | awk '/plugin script:/ { print $NF }'` install delete-by-query
    ```

## Setup

1. Edit `gitlab-ee/config/gitlab.yml` to enable Elasticsearch:

    ```yaml
    ## Elasticsearch (EE only)
    # Enable it if you are going to use elasticsearch instead of
    # regular database search
    elasticsearch:
      enabled: true
      # host: localhost
      # port: 9200
    ```

1. Start Elasticsearch by either running `elasticsearch` in a new terminal, or
   by adding it to your `Procfile`:

    ```
    elasticsearch: elasticsearch
    ```

1. Be sure to restart the GDK's `foreman` instance if it's running.

1. Perform a manual update of the Elasticsearch indexes:

    ```sh
    cd gitlab-ee && bundle exec rake gitlab:elastic:index
    ```
