# GitLab development with Unicorn

Even though our prefered web server is Puma, there are times you'd want to use Unicorn.

To use Unicorn: set environment variable `USE_WEB_SERVER=unicorn` before `gdk run`.
For example, in the GDK root:
  `echo "USE_WEB_SERVER=unicorn" >> .env`
or,
  `USE_WEB_SERVER=unicorn gdk run`
