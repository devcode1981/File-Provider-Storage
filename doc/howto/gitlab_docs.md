# Setting up GitLab Docs

Our CI includes [some checks][lint] for the documentation in GitLab. In order
to run the relative links checks locally or preview the changes, do the following:

1. Pull the `gitlab-docs` repo from within your GDK directory:

    ```
    make gitlab-docs-setup
    ```

1. Change directory:

    ```
    cd gitlab-docs/
    ```

1. Create the HTML files:

    ```
    bundle exec nanoc
    ```

1. Run the internal links check:

    ```
    bundle exec nanoc check internal_links
    ```

1. (Optionally) Preview the docs site locally:

    ```
    bundle exec nanoc live -p 3005
    ```

    Visit <http://127.0.0.1:3005/docs/README.html>.

> Global navigation links (left-hand pane) are not supported.

[lint]: https://docs.gitlab.com/ee/development/writing_documentation.html#testing
