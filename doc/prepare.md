# Preparing your computing environment for GDK

## Native installation setup

### Prerequisites for all platforms

If you do not have the dependencies below you will experience strange errors
during installation.

1. A non-root Unix user, this can be your normal user but **DO NOT** run the
   installation as a root user
1. Ensure the current [`gitlab-ce` Ruby version](https://gitlab.com/gitlab-org/gitlab-ce/blob/master/.ruby-version) is installed with a Ruby version manager
   ([RVM](https://rvm.io/), [rbenv], [chruby], etc.) and activated (for example by closing and reopening the terminal).
   **DO NOT** use the system Ruby. You can check the active version with the command `ruby --version`.
1. Make sure to close and reopen the terminal after installing a Ruby version manager.
1. Bundler, which you can install with `gem install bundler`
1. We recommend using Git version 2.18 or higher.
1. Node **8.x (LTS)** and Yarn 1.2 or newer. If your package manager does not
   have Node 8.x or yarn available, visit the official
   websites for [node] and [yarn] for installation instructions.
1. Go 1.9.6 or newer. If your package manager does not have up-to-date versions
   of Go available, visit the official website for [go] for installation instructions.
1. [Google Chrome] 60 or greater with [ChromeDriver] version 2.33 or greater.
   Visit the [installation details](https://sites.google.com/a/chromium.org/chromedriver/getting-started) for more details.
1. PostgreSQL 9.x, PostgreSQL 10.x is not yet supported.
1. [GraphicsMagick]

[rbenv]: https://github.com/rbenv/rbenv
[chruby]: https://github.com/postmodern/chruby
[node]: https://nodejs.org/en/download/
[yarn]: https://yarnpkg.com/en/docs/install/
[go]: https://golang.org/doc/install
[Google Chrome]: https://www.google.com/chrome/
[ChromeDriver]: https://sites.google.com/a/chromium.org/chromedriver/downloads
[GraphicsMagick]: http://www.graphicsmagick.org

### OS X 10.9 (Mavericks), 10.10 (Yosemite), 10.11 (El Capitan), macOS 10.12 (Sierra), macOS 10.13 (High Sierra)

Please read [the prerequisites for all platforms](#prerequisites-for-all-platforms).

We are using PostgreSQL 9.6 in the following example. If you want to use another version, please adjust paths accordingly.

#### Install OS X prerequisites using homebrew

We recommend manual installation of Node LTS, and not using Homebrew,
to avoid breaking your development setup when you run `brew upgrade`.
Install NodeJS 8.x LTS [manually](https://nodejs.org/en/download/),
or use a tool like [NVM](https://github.com/creationix/nvm).

```
brew install git redis postgresql@9.6 libiconv icu4c pkg-config cmake go openssl coreutils re2 graphicsmagick
brew install yarn --without-node
bundle config build.eventmachine --with-cppflags=-I/usr/local/opt/openssl/include
echo 'export PATH="/usr/local/opt/postgresql@9.6/bin:$PATH"' >> ~/.bash_profile
source ~/.bash_profile
```

#### Install OS X prerequisites using macports

```
sudo port install git redis libiconv postgresql96-server icu pkgconfig cmake nodejs8 go openssl npm5 yarn coreutils re2 GraphicsMagick
bundle config build.eventmachine --with-cppflags=-I/opt/local/include/openssl
echo 'export PATH=/opt/local/lib/postgresql96/bin/:$PATH' >> ~/.profile
source ~/.profile
```

### Linux

**Note:** Unless already set, you will likely have to increase the watches limit of `inotify` in order for frontend development tools such as `webpack` and `karma` to effectively track file changes. [See here](https://confluence.jetbrains.com/display/IDEADEV/Inotify+Watches+Limit) for details and instructions on how to apply this change.

#### Ubuntu

Please read [the prerequisites for all platforms](#prerequisites-for-all-platforms).

You can install NodeJS 8.x from [nodesource APT servers](https://nodejs.org/en/download/package-manager/#debian-and-ubuntu-based-linux-distributions).
Install Yarn from [a custom APT server](https://yarnpkg.com/lang/en/docs/install/#debian-stable) as well.

```
# Add apt-add-repository helper script
sudo apt-get install software-properties-common python-software-properties
# This PPA contains an up-to-date version of Go
sudo add-apt-repository ppa:longsleep/golang-backports
# This PPA contains an up-to-date version of git
sudo add-apt-repository ppa:git-core/ppa
sudo apt-get update
sudo apt-get install git postgresql postgresql-contrib libpq-dev redis-server libicu-dev cmake g++ libre2-dev libkrb5-dev libsqlite3-dev golang-1.10-go ed pkg-config graphicsmagick
```

Ubuntu 14.04 (Trusty Tahr) doesn't have the `libre2-dev` package available, but
you can [install re2 manually](https://github.com/google/re2/wiki/Install).

#### Arch Linux

Please read [the prerequisites for all platforms](#prerequisites-for-all-platforms).

```
pacman -S postgresql redis postgresql-libs icu npm ed cmake openssh git go re2 unzip graphicsmagick
```

#### Debian

Please read [the prerequisites for all platforms](#prerequisites-for-all-platforms).

```
sudo apt-get install postgresql postgresql-contrib libpq-dev redis-server libicu-dev cmake g++ libkrb5-dev libre2-dev ed pkg-config graphicsmagick
```

If you are running Debian Experimenal or newer you can install a Go
compiler via your package manager: `sudo apt-get install golang`.
Otherwise you need to install it manually. See [go] official installation
instructions.

You may need to install Redis 2.8 or newer manually.

#### Fedora

We assume you are using Fedora >= 22.

If you are running Fedora < 27 you'll need to install `go` manually using [go] official installation instructions.

>**Note:** Fedora 28+ ships PostgreSQL 10.x in default repositories, you can use `postgresql:9.6` module to install PostgreSQL 9.6.
But keep in mind that will replace the PostgreSQL 10.x package, so you cannot use both versions at once.

```sh
sudo dnf install fedora-repos-modular
sudo dnf module enable postgresql:9.6
```

```
sudo dnf install postgresql libpqxx-devel postgresql-libs redis libicu-devel nodejs git ed cmake rpm-build gcc-c++ krb5-devel go postgresql-server postgresql-contrib re2 GraphicsMagick
```

You may need to install Redis 2.8 or newer manually.

#### CentOS

Please read [the prerequisites for all platforms](#prerequisites-for-all-platforms).

This is tested on CentOS 6.5:

```
sudo yum install https://download.postgresql.org/pub/repos/yum/9.6/redhat/rhel-6-x86_64/pgdg-centos96-9.6-3.noarch.rpm
sudo yum install https://download.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
sudo yum install postgresql96-server postgresql96-devel libicu-devel git cmake gcc-c++ redis ed fontconfig freetype libfreetype.so.6 libfontconfig.so.1 libstdc++.so.6 nodejs npm re2 re2-devel GraphicsMagick

bundle config build.pg --with-pg-config=/usr/pgsql-9.6/bin/pg_config
# This example uses Ruby 2.4.4. Substitute with the current version if different.
sudo rvm install 2.4.4
sudo rvm use 2.4.4
#Ensure your user is in rvm group
sudo usermod -a -G rvm <username>
#add iptables exceptions, or sudo service stop iptables
```

Install `go` manually using [go] official installation instructions.

Git 1.7.1-3 is the latest git binary for CentOS 6.5 and GitLab. Spinach tests
will fail due to a higher version requirement by GitLab. You can follow the
instructions found [in the GitLab recipes repository][puias] to install a newer
binary version of Git.

You may need to install Redis 2.8 or newer manually.

#### OpenSUSE

Please read [the prerequisites for all platforms](#prerequisites-for-all-platforms).

This was tested on OpenSUSE LEAP 42.1, and Tumbleweed (20161109)


```
sudo zypper dup

sudo zypper install libxslt-devel  postgresql postgresql-devel libpqxx-devel redis libicu-devel nodejs git ed cmake \
         rpm-build gcc-c++ krb5-devel postgresql-server postgresql-contrib \
         libxml2-devel libxml2-devel-32bit findutils-locate re2 GraphicsMagick
```

On leap 42.1 you also need:
```
sudo zypper install ld.charlock_holmes "--with-icu-dir=/usr/local" --globalnpm4
```

Install `go` manually using [go] official installation instructions.


The following `bundle config` options are recommended before you run `gdk install` in order to avoid problems with the embedded libraries inside nokogiri:

```
bundle config build.nokogiri "--use-system-libraries" --global
```
for tumbleweed only:
```
bundle config build.charlock_holmes "--with-icu-dir=/usr/local" --global
```

Manual fix required on OpenSUSE LEAP to place redis-server in the path for non-root users:
```
sudo ln -s /usr/sbin/redis-server /usr/bin/redis-server
```

#### FreeBSD

Please read [the prerequisites for all platforms](#prerequisites-for-all-platforms).

```
sudo pkg install postgresql93-server postgresql93-contrib postgresql-libpqxx \
redis go node icu krb5 gmake re2 GraphicsMagick
```

### **Experimental** Windows 10 using the WSL (Windows Subsystem for Linux)

**Setting up the Windows Subsystem for Linux:**

Open PowerShell as Administrator and run:
```
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux
```
Restart your computer when prompted.

Install your Linux Distribution of Choice via the Windows Store. Currently the distro options are:

    Ubuntu
    OpenSUSE
    SLES
    Kali Linux
    Debian GNU/Linux

Launch the distro of choice.

Return to the prerequisite installation steps.

**Installing the remaining GDK Tools & resources**

Install NodeJS from source

```
curl -O https://nodejs.org/dist/v8.12.0/node-v8.12.0.tar.gz
tar -zxf node-v8.12.0.tar.gz
cd node-v8.12.0
```
Build the NodeJS library. The following instructions are copied from the NodeJS BUILDING.md document:

```
sudo apt-get install build-essential
./configure
make -j4 # adjust according to your available CPU capacity
sudo make install
```

Install the current `gitlab-ce` Ruby version using [RVM](https://rvm.io/):

```
# This example uses Ruby 2.4.4. Substitute with the current version if different.
rvm install 2.4.4
rvm use 2.4.4
```

Install yarn

```
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
sudo apt-get update && sudo apt-get install yarn
```

Install the remainder of the prerequisites
```
# Add apt-add-repository helper script
sudo apt-get install software-properties-common python-software-properties
# This PPA contains an up-to-date version of Go
sudo apt-add-repository -y ppa:ubuntu-lxc/lxd-stable
sudo apt-get update
sudo apt-get install git postgresql postgresql-contrib libpq-dev redis-server libicu-dev cmake g++ libkrb5-dev libre2-dev golang ed pkg-config
```

Start the PostgreSQL database

```
sudo service postgresql start
```

For some common troubleshooting steps for Windows 10 GDK installs please refer to [Troubleshooting](./howto/troubleshooting.md)

### Other platforms

If you got GDK running an another platform please send a merge request to add
it here.

### Next Steps

After you have completed everything here, please proceed to [Set-up GDK](./set-up-gdk.md)

[puias]: https://gitlab.com/gitlab-org/gitlab-recipes/tree/master/install/centos#add-puias-computational-repository
[docker engine]: https://docs.docker.com/engine/installation/
[vagrant]: https://www.vagrantup.com
