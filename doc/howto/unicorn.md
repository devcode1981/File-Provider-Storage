# GitLab development with Unicorn

Even though our prefered web server is Puma, there are times you'd want to use Unicorn.

To use Unicorn, set environment variable `USE_WEB_SERVER=unicorn`.
In the GDK root:

```sh
echo 'export USE_WEB_SERVER=unicorn' >> env.runit
gdk restart rails-web
```

To switch back to Puma, remove the `USE_WEB_SERVER` line from `env.runit` and restart.
