# NGINX

Installing and configuring NGINX will allow you to enable HTTPS, HTTP/2 as
well as greater flexibility around HTTP routing.

## Install dependencies

You'll need to install `NGINX`:

```sh
# on macOS
brew install nginx

# on Debian/Ubuntu
apt install nginx

# on Fedora
yum install nginx
```

## Add entry to /etc/hosts

To be able to use a hostname instead of IP address, add a line to
`/etc/hosts`.

```sh
echo '127.0.0.1 gdk.test' | sudo tee -a /etc/hosts
```

`gdk.test` (or anything ending in `.test`) is recommended as `.test` is a
[reserved TLD for testing software](https://en.wikipedia.org/wiki/.test).

### Configuring a loopback device (optional)

If you want an isolated network space for all the services of your
GDK, you can add a lookback network interface:

```sh
# on macOS
sudo ifconfig lo0 alias 127.1.1.1

# on GNU/Linux
sudo ifconfig lo:1 127.1.1.1
```

And add that address to `/etc/hosts`:

```sh
echo '127.1.1.1 gdk.test' | sudo tee -a /etc/hosts
```

## Update `gdk.yml`

Place the following settings in your `gdk.yml`:

```yaml
---
hostname: gdk.test
nginx:
  enabled: true
  http:
    enabled: true
```

## Update `gdk.yml` for HTTPS (optional)

Place the following settings in your `gdk.yml`:

```yaml
---
hostname: gdk.test
port: 3443
https:
  enabled: true
nginx:
  enabled: true
  ssl:
    certificate: gdk.test.pem
    key: gdk.test-key.pem
```

### Generate certificate

[`mkcert`](https://github.com/FiloSottile/mkcert) is needed to generate certificates.
Check out their [installation instructions](https://github.com/FiloSottile/mkcert#installation)
for all the different platforms.

On macOS, install with `brew`:

```sh
brew install mkcert
mkcert -install
```

Using `mkcert` you can generate a self-signed certificate. It also
ensures your browser and OS trust the certificate.

```sh
mkcert gdk.test
```

## Update `gdk.yml` for HTTP/2 (optional)

Place the following settings in your `gdk.yml`:

```yaml
---
hostname: gdk.test
port: 3443
https:
  enabled: true
nginx:
  enabled: true
  http2:
    enabled: true
  ssl:
    certificate: gdk.test.pem
    key: gdk.test-key.pem
```

## Configure GDK

Run the following to apply these changes:

```sh
gdk reconfigure
gdk restart
```

## Run

GitLab should now be available for:

- HTTP: <http://gdk.test:8080>
- HTTPS: <https://gdk.test:3443> (if you set up HTTPS).
