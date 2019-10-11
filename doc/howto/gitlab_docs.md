# Setting up GitLab Docs

Our CI includes [some checks](https://docs.gitlab.com/ee/development/documentation/index.html#testing) for the documentation in GitLab. In order
to run the relative links checks locally or preview the changes, do the following:

1. Pull the `gitlab-docs` repo from within your GDK directory:

   ```sh
   make gitlab-docs-setup
   ```

1. Change directory:

   ```sh
   cd gitlab-docs/
   ```

1. Create the HTML files:

   ```sh
   bundle exec nanoc
   ```

1. Run the internal links check:

   ```sh
   bundle exec nanoc check internal_links
   ```

1. Run the internal anchors check:

   ```sh
   bundle exec nanoc check internal_anchors
   ```

1. (Optionally) Preview the docs site locally:

   ```sh
   bundle exec nanoc live -p 3005
   ```

   Visit <http://127.0.0.1:3005/ee/README.html>.

   If you see the following message, another process is already listening on port `3005`:

   ```sh
   Address already in use - bind(2) for 127.0.0.1:3005 (Errno::EADDRINUSE)`
   ```

   Select another port and try again.
