# HTTPS

## Install dependencies

You'll need to install `nginx`:

```sh
# on macOS
brew install nginx

# on Debian/Ubuntu
apt install nginx

# on Fedora
yum install nginx
```

This guide is also using [`mkcert`](https://github.com/FiloSottile/mkcert).
Check out their [installation instructions](https://github.com/FiloSottile/mkcert#installation)
for all the different platforms, but on macOS you can just run:

```sh
brew install mkcert
```

## Add entry to /etc/hosts

To be able to use a hostname instead of IP address, add a line to
`/etc/hosts`.

```sh
echo '127.0.0.1 gdk.localhost' | sudo tee --append /etc/hosts
```

### Configuring a loopback device (optionally)

If you like an isolated network space for all the services of your
GDK, you can add a lookback network interface:

```sh
# on macOS
sudo ifconfig lo1 alias 127.1.1.1

# on GNU/Linux
sudo ifconfig lo:1 127.1.1.1
```

And add that address to `/etc/hosts`:

```sh
echo '127.1.1.1 gdk.localhost' | sudo tee --append /etc/hosts
```

## Generate certificate

Using `mkcert` you can generate a self-signed certificate. It also
ensures your browser and OS trust the certificate.

```sh
mkcert gdk.localhost 127.1.1.1
```

## Configure GDK

Place the following settings in your `gdk.yml`:

```yaml
---
hostname: gdk.localhost
port: 3443
https:
  enabled: true
nginx:
  enabled: true
  ssl:
    certificate: gdk.localhost+1.pem
    key: gdk.localhost+1-key.pem
```

Run `gdk reconfigure` to apply these changes.

## Run

Everything is now configured and `gdk start` will make your
GitLab available on [`gdk.localhost:3443`](https://gdk.localhost:3443).
