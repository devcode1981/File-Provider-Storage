# Preparing your computing environment for GDK

The preferred way to use GitLab Development Kit is to install Ruby and
dependencies on your 'native' OS. We strongly recommend the native install
since it is much faster than a virtualized one. Due to heavy IO operations a
virtualized installation will be much slower running the app and the tests.

If you want to use [Vagrant] instead (e.g. need to do development from Windows),
see [the instructions for our (experimental) Vagrant with Virtualbox setup](vagrant.md#vagrant-with-virtualbox).

If you want to use [Vagrant] with [Docker][docker engine] on Linux,
see [the instructions for our (experimental) Vagrant with Docker setup](vagrant.md#vagrant-with-docker).

## Native installation setup

### Prerequisites for all platforms

If you do not have the dependencies below you will experience strange errors
during installation.

1. A non-root Unix user, this can be your normal user but **DO NOT** run the
   installation as a root user
2. Ruby 2.3 (2.3.1 or newer) installed with a Ruby version manager
   ([RVM](https://rvm.io/), rbenv, chruby, etc.), **DO NOT** use the
   system Ruby
3. Bundler, which you can install with `gem install bundler`

### OS X 10.9 (Mavericks), 10.10 (Yosemite), 10.11 (El Capitan)

Please read [the prerequisites for all platforms](#prerequisites-for-all-platforms).

```
brew tap homebrew/dupes
brew tap homebrew/versions
brew install git redis postgresql libiconv icu4c pkg-config cmake nodejs go openssl node npm
bundle config build.eventmachine --with-cppflags=-I/usr/local/opt/openssl/include
npm install phantomjs-prebuilt@2.1.12 -g
```

### Ubuntu

Please read [the prerequisites for all platforms](#prerequisites-for-all-platforms).

```
# Add apt-add-repository helper script
sudo apt-get install software-properties-common python-software-properties
# This PPA contains an up-to-date version of Go
sudo apt-add-repository -y ppa:ubuntu-lxc/lxd-stable
sudo apt-get update
sudo apt-get install git postgresql postgresql-contrib libpq-dev redis-server libicu-dev cmake g++ nodejs libkrb5-dev golang ed pkg-config
npm install phantomjs-prebuilt@2.1.12 -g
```

### Arch Linux

Please read [the prerequisites for all platforms](#prerequisites-for-all-platforms).

```
pacman -S postgresql redis postgresql-libs icu nodejs ed cmake openssh git go
npm install phantomjs-prebuilt@2.1.12 -g
```

### Debian

Please read [the prerequisites for all platforms](#prerequisites-for-all-platforms).

```
sudo apt-get install postgresql postgresql-contrib libpq-dev redis-server libicu-dev cmake g++ nodejs libkrb5-dev ed pkg-config
```

If you are running Debian Stretch or newer you will need to install Go
compiler as well: `sudo apt-get install golang`.

You need to install phantomjs manually:

```
PHANTOM_JS="phantomjs-2.1.1-linux-x86_64"
cd ~
wget https://bitbucket.org/ariya/phantomjs/downloads/$PHANTOM_JS.tar.bz2
tar -xvjf $PHANTOM_JS.tar.bz2
sudo mv $PHANTOM_JS /usr/local/share
sudo ln -s /usr/local/share/$PHANTOM_JS/bin/phantomjs /usr/local/bin
phantomjs --version
```

You may need to install Redis 2.8 or newer manually.

### Fedora

We assume you are using Fedora >= 22.

```
sudo dnf install postgresql libpqxx-devel postgresql-libs redis libicu-devel nodejs git ed cmake rpm-build gcc-c++ krb5-devel go postgresql-server postgresql-contrib
```

Install `phantomJS` manually, or download it and put in your $PATH. For
instructions, follow the [Debian guide on phantomJS](#debian).

You may need to install Redis 2.8 or newer manually.

### CentOS

Please read [the prerequisites for all platforms](#prerequisites-for-all-platforms).

This is tested on CentOS 6.5:

```
sudo yum install http://yum.postgresql.org/9.3/redhat/rhel-6-x86_64/pgdg-redhat93-9.3-1.noarch.rpm
sudo yum install https://download.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
sudo yum install postgresql93-server libicu-devel cmake gcc-c++ redis ed fontconfig freetype libfreetype.so.6 libfontconfig.so.1 libstdc++.so.6 golang nodejs

sudo rvm install 2.3
sudo rvm use 2.3
#Ensure your user is in rvm group
sudo usermod -a -G rvm <username>
#add iptables exceptions, or sudo service stop iptables
```

Install `phantomJS` manually, or download it and put in your $PATH. For
instructions, follow the [Debian guide on phantomJS](#debian).

Git 1.7.1-3 is the latest git binary for CentOS 6.5 and GitLab. Spinach tests
will fail due to a higher version requirement by GitLab. You can follow the
instructions found [in the GitLab recipes repository][puias] to install a newer
binary version of Git.

You may need to install Redis 2.8 or newer manually.

### Other platforms

If you got GDK running an another platform please send a merge request to add
it here.

## Installation

The `Makefile` will clone the repositories, install the Gem bundles and set up
basic configuration files. Pick one:

[puias]: https://gitlab.com/gitlab-org/gitlab-recipes/tree/master/install/centos#add-puias-computational-repository
[docker engine]: https://docs.docker.com/engine/installation/
[vagrant]: https://www.vagrantup.com
