# HTTPS

If you want to access GitLab via HTTPS in development you can use
NGINX. On OS X you can install NGINX with `brew install nginx`.

First generate a key and certificate for localhost:

```
make localhost.crt
```

On OS X you can add this certificate to the trust store with:
`security add-trusted-cert localhost.crt`.

Next make sure that HTTPS is enabled in gitlab/config/gitlab.yml: look
for the `https:` and `port:` settings.

Uncomment the `nginx` line in your Procfile. Now `gdk run app`
(and `gdk run`) will start NGINX listening on https://localhost:3443.

If you are using a port other than localhost:3000 for
gitlab-workhorse, or if you want to use a port other than
localhost:3443 for NGINX, please edit `nginx/conf/nginx.conf`.
