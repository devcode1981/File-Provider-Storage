# Preparing your computing environment for GDK

Before [setting up GDK](index.md), your local environment must have
prerequisite software installed and configured.

## Prerequisites for all platforms

_TLDR: see sample package manager commands (`brew`, `apt`, and so on) listed in [Platform-specific setup](#platform-specific-setup) below for quick installation._

Make sure you follow all the guidelines and resolve all the dependencies listed below before installing GDK. Otherwise, you will experience strange errors during installation.

| Prerequisite      | Description                                                                                                                                                                                                                                                                                                                                                                 |
| -------------- | -----------                                                                                                                                                                                                                                                                                                                                                                 |
| User account   | Use a **non-root** Unix user to install GDK. This can be your normal user, but **DO NOT** run the installation as a root user.                                                                                                                                                                                                                                              |
| [Ruby](#ruby) | The current [`gitlab` Ruby version](https://gitlab.com/gitlab-org/gitlab/blob/master/.ruby-version).                                                |
| Bundler        | <p>Install the version of Bundler specified in this [Gemfile.lock](https://gitlab.com/gitlab-org/gitlab/blob/master/Gemfile.lock), as noted with the `BUNDLED WITH` text at the end of the file.</p><p> To install Bundler, use the following command: `gem install bundler -v <version>`. Replace `<version>` with the `BUNDLED WITH` version.</p>                                            |
| Git            | <p>We recommend using Git version 2.26 or higher (minimal supported version is 2.22).</p><p>Git installation is covered in the instructions in the [Platform-specific setup](#platform-specific-setup).</p><p>For checking out test fixtures, you will also need Git LFS.</p> |
| Git LFS        | <p>We recommend using Git LFS version 2.10 or higher (minimal supported version is 1.0.1).</p><p>Git LFS installation is covered in the instructions in the [Platform-specific setup](#platform-specific-setup).</p> |
| Node.js        | <p>Node.js **12.10** and Yarn 1.12 or newer.</p><p>Node.js and Yarn installation is covered in the instructions below. If your package manager does not have Node.js 12.10 or yarn available, visit the official websites for [Node](https://nodejs.org/en/download/) and [Yarn](https://yarnpkg.com/en/docs/install/) for installation instructions.</p> |
| Go             | <p>Go 1.14.</p><p>Go installation is covered in the instructions below. If your package manager does not have up-to-date versions of Go available, visit the official [Go](https://golang.org/doc/install) website for installation instructions.</p>                                                                                                              |
| Google Chrome  | [Google Chrome](https://www.google.com/chrome/) 60 or greater with [ChromeDriver](https://sites.google.com/a/chromium.org/chromedriver/downloads) version 2.33 or greater. Visit the Chrome Driver [Getting started](https://sites.google.com/a/chromium.org/chromedriver/getting-started) page for more details.                                                           |
| PostgreSQL     | <p>PostgreSQL version 11.x.</p><p>PostgreSQL installation is covered in the instructions [below](#platform-specific-setup). Some instructions still pin the version of PostgreSQL to version 10. Please update the documentation steps to version 11 as you successfully install PostreSQL 11 on your platform.</p> |
| GraphicsMagick | GraphicsMagick installation is covered in the instructions [below](#platform-specific-setup).                                                                                                                                                                                                                                                                                                           |
| Exiftool       | Exiftool installation is covered in the instructions [below](#platform-specific-setup).                                                                                                                                                                                                                                                                                                           |
| runit          | runit installation is covered in the instructions [below](#platform-specific-setup).                                                                                                                                                                                                                                                                                                           |
| MinIO          | MinIO installation is covered in the instructions [below](#platform-specific-setup).                                                                                                                                                                                                                                                                                                           |

## Ruby

Check your active Ruby version with `ruby --version`. It must match the
the current [`gitlab` Ruby version](https://gitlab.com/gitlab-org/gitlab/blob/master/.ruby-version).
**DO NOT** use the Ruby version that comes with your OS. For the sake of ease
of use, we recommend using a Ruby version manager such as:

1. [rbenv](https://github.com/rbenv/rbenv#installation) - _Generally preferred, most lightweight_
1. [RVM](https://rvm.io/)
1. [chruby](https://github.com/postmodern/chruby#install)

**Note:** you may have to close and reopen the terminal after installing a Ruby
version manager to read new `PATH` variables added for Ruby executable files.

## Platform-specific setup

To start preparing the GDK installation, pick your platform of choice:

| [macOS](#macos) | [Ubuntu](#ubuntu) | [Arch Linux](#arch-linux) | [Debian](#debian) | [Fedora](#fedora) | [CentOS](#centos) | [OpenSUSE](#opensuse) | [FreeBSD](#freebsd) | [Windows 10](#windows-10) |
|-|-|-|-|-|-|-|-|-|

### macOS

Supported versions: OS X 10.9 (Mavericks) and up.

In OS X 10.15 the default shell changed from Bash to Zsh. The instructions below for Homebrew and
MacPorts handle Bash or Zsh slightly differently by setting a `shell_file` variable based on your current shell.

Please read [the prerequisites for all platforms](#prerequisites-for-all-platforms).

We are using PostgreSQL 11 in the following example. If you want to use another version, please adjust paths accordingly.

#### Install macOS prerequisites using Homebrew

[Homebrew](https://brew.sh/) is a package manager for macOS that allows you to easily install programs
and tools through the Terminal. Visit their website for installation details.

| **Note on the Homebrew installation directory** |
| ------ |
| We strongly recommend using the default installation directory for Homebrew `/usr/local`. This makes it a lot easier to install Ruby gems with C extensions. If you use a custom directory, you will have to do a lot of extra work when installing Ruby gems. For more information, see [Why does Homebrew prefer I install to /usr/local?](https://docs.brew.sh/FAQ#why-does-homebrew-prefer-i-install-to-usrlocal). |

| **Note on Node.js** |
| ------------------- |
| We recommend manual installation of Node.js 12.10 instead of using Homebrew to avoid breaking your development setup when you run `brew upgrade`. Install Node.js 12.10 [manually](https://nodejs.org/en/download/) or use a tool like [NVM](https://github.com/creationix/nvm). If you want to use Homebrew, you can prevent it from upgrading the current Node.js formula by pinning it with `brew pin node@12`. |

```shell
brew install git git-lfs redis postgresql@11 libiconv pkg-config cmake go openssl coreutils re2 graphicsmagick node@12 gpg runit icu4c exiftool sqlite minio/stable/minio
ln -ns /usr/local/opt/node@12 /usr/local/opt/node || true # otherwise yarn installation cannot find node
brew install yarn --ignore-dependencies
brew link pkg-config
brew pin node@12 icu4c readline
bundle config build.eventmachine --with-cppflags=-I/usr/local/opt/openssl/include
if [ ${ZSH_VERSION} ]; then shell_file="${HOME}/.zshrc"; else shell_file="${HOME}/.bash_profile"; fi
echo 'export PATH="/usr/local/opt/postgresql@11/bin:/usr/local/opt/node@12/bin:$PATH"' >> ${shell_file}
echo 'export PKG_CONFIG_PATH="/usr/local/opt/icu4c/lib/pkgconfig:$PKG_CONFIG_PATH"' >> ${shell_file}
source ${shell_file}
brew cask install google-chrome chromedriver
```

#### Install macOS prerequisites using MacPorts

[MacPorts](https://www.macports.org/) is another package manager for macOS. Visit their website for installation details.

```shell
sudo port install git git-lfs redis libiconv postgresql11-server icu pkgconfig cmake nodejs12 go openssl npm5 yarn coreutils re2 GraphicsMagick runit exiftool minio sqlite3
bundle config build.eventmachine --with-cppflags=-I/opt/local/include/openssl
if [ ${ZSH_VERSION} ]; then shell_file="${HOME}/.zshrc"; else shell_file="${HOME}/.bash_profile"; fi
echo 'export PATH=/opt/local/lib/postgresql11/bin/:$PATH' >> ${shell_file}
source ${shell_file}
```

### Linux

**Note:** Unless already set, you will likely have to increase the watches limit of `inotify` in order for frontend development tools such as `webpack` and `karma` to effectively track file changes. [See here](https://confluence.jetbrains.com/display/IDEADEV/Inotify+Watches+Limit) for details and instructions on how to apply this change.

#### Ubuntu

Please read [the prerequisites for all platforms](#prerequisites-for-all-platforms).

1. Install **Node.js 12.10** from the [official Node.js binary distribution](https://github.com/nodesource/distributions/blob/master/README.md#debinstall).
1. Install **Yarn** from the [Yarn Debian package repository](https://yarnpkg.com/lang/en/docs/install/#debian-stable).
1. Install remaining dependencies; modify the `GDK_GO_VERSION` with the major.minor version number (currently 1.12) as needed:

   ```shell
   # Add apt-add-repository helper script
   sudo apt-get update
   sudo apt-get install software-properties-common
   [[ $(lsb_release -sr) < "18.04" ]] && sudo apt-get install python-software-properties
   # This PPA contains an up-to-date version of Go
   sudo add-apt-repository ppa:longsleep/golang-backports
   # Setup path for Go
   export GDK_GO_VERSION="1.14"
   export PATH="/usr/lib/go-${GDK_GO_VERSION}/bin:$PATH"
   # This PPA contains an up-to-date version of git
   sudo add-apt-repository ppa:git-core/ppa
   sudo apt-get install git git-lfs postgresql postgresql-contrib libpq-dev redis-server \
     libicu-dev cmake g++ g++-8 libre2-dev libkrb5-dev libsqlite3-dev golang-${GDK_GO_VERSION}-go ed \
     pkg-config graphicsmagick runit libimage-exiftool-perl rsync libssl-dev
   sudo curl https://dl.min.io/server/minio/release/linux-amd64/minio --output /usr/local/bin/minio
   sudo chmod +x /usr/local/bin/minio
   ```

   > ℹ️ Ubuntu 18.04 (Bionic Beaver) and beyond doesn't have `python-software-properties` as a separate package.
   >
   > ℹ️ Ubuntu 14.04 (Trusty Tahr) doesn't have the `libre2-dev` package available, but
   > you can [install re2 manually](https://github.com/google/re2/wiki/Install).

1. You're all set now. [Go to next steps](#next-steps).

#### Arch Linux

Please read [the prerequisites for all platforms](#prerequisites-for-all-platforms).

```shell
pacman -S postgresql redis postgresql-libs icu npm ed cmake openssh git git-lfs go re2 \
  unzip graphicsmagick perl-image-exiftool rsync yarn minio sqlite python2
```

>**Note:** The Arch Linux core repository does not contain anymore the `runit` package. It is required to install `runit-systemd` from the Arch User Repository (AUR) with an AUR package manager like `pacaur` ([https://github.com/E5ten/pacaur](https://github.com/E5ten/pacaur)) or `pikaur` ([https://github.com/actionless/pikaur](https://github.com/actionless/pikaur)). See [Arch Linux Wiki page AUR_helpers](https://wiki.archlinux.org/index.php/AUR_helpers) for more information.

```shell
pikaur -S runit-systemd
```

#### Debian

Please read [the prerequisites for all platforms](#prerequisites-for-all-platforms).

```shell
sudo apt-get install postgresql postgresql-contrib libpq-dev redis-server \
  libicu-dev cmake g++ libkrb5-dev libre2-dev ed pkg-config graphicsmagick \
  runit libimage-exiftool-perl rsync libsqlite3-dev
sudo curl https://dl.min.io/server/minio/release/linux-amd64/minio --output /usr/local/bin/minio
sudo chmod +x /usr/local/bin/minio
```

If you are running Debian [Experimental](https://wiki.debian.org/DebianExperimental), or [newer](https://packages.debian.org/search?keywords=golang-go) you can install a Go
compiler via your package manager: `sudo apt-get install golang`.
Otherwise you need to install it manually. See [Go](https://golang.org/doc/install#install) official installation
instructions.

You may need to install Redis 2.8 or newer manually.

#### Fedora

We assume you are using Fedora >= 22.

If you are running Fedora < 27 you'll need to install `go` manually using [go] official installation instructions.

>**Note:** Fedora 30+ ships PostgreSQL 11.x in default repositories, you can use `postgresql:10` module to install PostgreSQL 10.
But keep in mind that will replace the PostgreSQL 11.x package, so you cannot use both versions at once.

```shell
sudo dnf install fedora-repos-modular
sudo dnf module enable postgresql:10
```

```shell
sudo dnf install postgresql libpqxx-devel postgresql-libs redis libicu-devel \
  nodejs git git-lfs ed cmake rpm-build gcc-c++ krb5-devel go postgresql-server \
  postgresql-contrib re2 GraphicsMagick re2-devel sqlite-devel perl-Digest-SHA \
  perl-Image-ExifTool rsync
sudo curl https://dl.min.io/server/minio/release/linux-amd64/minio --output /usr/local/bin/minio
sudo chmod +x /usr/local/bin/minio
```

You may need to install Redis 2.8 or newer manually.

##### runit

You will also need to install [runit](http://smarden.org/runit) manually.

The following instructions worked for runit version 2.1.2 - but please make sure you read the up to date installation instructions on [the website](http://smarden.org/runit) before continuing.

1. Download and extract the runit source code to a local folder to compile it:

   ```shell
   wget http://smarden.org/runit/runit-2.1.2.tar.gz
   tar xzf runit-2.1.2.tar.gz
   cd admin/runit-2.1.2
   sed -i -E 's/ -static$//g' src/Makefile
   ./package/compile
   ./package/check
   ```

1. Make sure all binaries in `command/` are accessible from your `PATH` (e.g. symlink / copy them to `/usr/local/bin`)

#### CentOS

Please read [the prerequisites for all platforms](#prerequisites-for-all-platforms).

This is tested on CentOS 6.5:

```shell
sudo yum install https://download.postgresql.org/pub/repos/yum/10/redhat/rhel-6-x86_64/pgdg-centos10-10-2.noarch.rpm
sudo yum install https://download.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
sudo yum install postgresql10-server postgresql10-devel libicu-devel git git-lfs cmake \
  gcc-c++ redis ed fontconfig freetype libfreetype.so.6 libfontconfig.so.1 \
  libstdc++.so.6 nodejs npm re2 re2-devel GraphicsMagick runit perl-Image-ExifTool \
  rsync sqlite-devel
sudo curl https://dl.min.io/server/minio/release/linux-amd64/minio --output /usr/local/bin/minio
sudo chmod +x /usr/local/bin/minio

bundle config build.pg --with-pg-config=/usr/pgsql-10/bin/pg_config
# This example uses Ruby 2.6.6. Substitute with the current version if different.
sudo rvm install 2.6.6
sudo rvm use 2.6.6
#Ensure your user is in rvm group
sudo usermod -a -G rvm <username>
#add iptables exceptions, or sudo service stop iptables
```

Install `go` manually using [go] official installation instructions.

Git 1.7.1-3 is the latest Git binary for CentOS 6.5 and GitLab. Spinach tests
will fail due to a higher version requirement by GitLab. You can follow the
instructions found [in the GitLab recipes repository](https://gitlab.com/gitlab-org/gitlab-recipes/tree/master/install/centos#add-puias-computational-repository) to install a newer
binary version of Git.

You may need to install Redis 2.8 or newer manually.

#### OpenSUSE

Please read [the prerequisites for all platforms](#prerequisites-for-all-platforms).

This was tested on OpenSUSE LEAP 42.1, and Tumbleweed (20161109)

```shell
sudo zypper dup
sudo zypper install libxslt-devel  postgresql postgresql-devel libpqxx-devel redis libicu-devel nodejs git git-lfs ed cmake \
        rpm-build gcc-c++ krb5-devel postgresql-server postgresql-contrib \
        libxml2-devel libxml2-devel-32bit findutils-locate re2 GraphicsMagick \
        runit exiftool rsync sqlite3-devel
sudo curl https://dl.min.io/server/minio/release/linux-amd64/minio --output /usr/local/bin/minio
sudo chmod +x /usr/local/bin/minio
```

On leap 42.1 you also need:

```shell
sudo zypper install ld.charlock_holmes "--with-icu-dir=/usr/local" --globalnpm4
```

Install `go` manually using [go] official installation instructions.

The following `bundle config` options are recommended before you run `gdk install` in order to avoid problems with the embedded libraries inside nokogiri:

```shell
bundle config build.nokogiri "--use-system-libraries" --global
```

for tumbleweed only:

```shell
bundle config build.charlock_holmes "--with-icu-dir=/usr/local" --global
```

Manual fix required on OpenSUSE LEAP to place `redis-server` in the path for non-root users:

```shell
sudo ln -s /usr/sbin/redis-server /usr/bin/redis-server
```

#### FreeBSD

Please read [the prerequisites for all platforms](#prerequisites-for-all-platforms).

```shell
sudo pkg install postgresql10-server postgresql10-contrib postgresql-libpqxx \
redis go node icu krb5 gmake re2 GraphicsMagick p5-Image-ExifTool git-lfs minio sqlite3
```

### Windows 10

> 🚨 Support for Windows 10 is **experimental**, via the Windows Subsystem for Linux (WSL).

**Setting up the Windows Subsystem for Linux:**

Open PowerShell as Administrator and run:

```shell
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux
```

Restart your computer when prompted.

Install your Linux Distribution of Choice via the Windows Store. Currently the distro options are:

- Ubuntu
- OpenSUSE
- SLES
- Kali Linux
- Debian GNU/Linux

Launch the distro of choice.

Return to the prerequisite installation steps.

**Installing the remaining GDK Tools & resources**

Install Node.js from source:

```shell
curl -O https://nodejs.org/dist/v12.10.0/node-v12.10.0.tar.gz
tar -zxf node-v12.10.0.tar.gz
cd node-v12.10.0
```

Build the Node.js library. The following instructions are copied from the Node.js BUILDING.md document:

```shell
sudo apt-get install build-essential
./configure
make -j4 # adjust according to your available CPU capacity
sudo make install
```

Install yarn

```shell
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
sudo apt-get update && sudo apt-get install yarn
```

Install the remainder of the prerequisites

```shell
# Add apt-add-repository helper script
sudo apt-get install software-properties-common python-software-properties
sudo apt-get update
sudo apt-get install git git-lfs postgresql postgresql-contrib libpq-dev redis-server \
  libicu-dev cmake g++ libkrb5-dev libre2-dev golang ed pkg-config runit
```

Start the PostgreSQL database (SystemV)

```shell
sudo service postgresql start
```

Start the PostgreSQL database (SystemD)

```shell
sudo systemctl enable postgresql
sudo systemctl start postgresql
```

For some common troubleshooting steps for Windows 10 GDK installs please refer to [Troubleshooting](troubleshooting.md)

## Documentation tools

Linting for GDK documentation is performed by:

- markdownlint.
- Vale.

For more information and instructions on installing tooling and plugins for editors, see
[Linting](https://docs.gitlab.com/ee/development/documentation/#linting).

## Next Steps

After you have completed everything here, [set up GDK](index.md).
