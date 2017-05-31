# Elasticsearch

GitLab Enterprise Edition has Elasticsearch integration. In this
document we explain how to set this up in your development
environment.

## Installation: macOS

1. Install Java 1.8 + (Elasticsearch dependency)

    ```sh
    brew cask install java
    ```

1. Install Elasticsearch with [Homebrew]:

    ```sh
    brew install elasticsearch
    ```

1. Install the `delete-by-query` plugin:

    ```sh
    `brew info elasticsearch | awk '/plugin script:/ { print $NF }'` install delete-by-query
    ```

## Setup

1. Go to **Admin > Application Settings** to enable Elasticsearch.

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
