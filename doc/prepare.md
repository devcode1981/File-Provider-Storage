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
   ([RVM](https://rvm.io/), [rbenv], [chruby], etc.), **DO NOT** use the
   system Ruby
3. Bundler, which you can install with `gem install bundler`

[rbenv]: https://github.com/rbenv/rbenv
[chruby]: https://github.com/postmodern/chruby

### OS X 10.9 (Mavericks), 10.10 (Yosemite), 10.11 (El Capitan), macOS 10.12 (Sierra)

Please read [the prerequisites for all platforms](#prerequisites-for-all-platforms).

#### Install OS X prerequisites using homebrew

```
brew tap homebrew/dupes
brew tap homebrew/versions
brew install git redis postgresql libiconv icu4c pkg-config cmake nodejs go openssl node npm
bundle config build.eventmachine --with-cppflags=-I/usr/local/opt/openssl/include
npm install phantomjs-prebuilt@2.1.12 -g
```

#### Install OS X prerequisites using macports

We are using PostgreSQL-9.5 in the following example. If you want to use another version, please adjust paths accordingly.

```
sudo port install git redis libiconv postgresql95-server icu pkgconfig cmake nodejs4 go openssl npm2
bundle config build.eventmachine --with-cppflags=-I/opt/local/include/openssl
sudo npm install phantomjs-prebuilt@2.1.12 -g
echo 'export PATH=/opt/local/lib/postgresql95/bin/:$PATH' >> ~/.profile
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

### OpenSUSE

Please read [the prerequisites for all platforms](#prerequisites-for-all-platforms).

This was tested on OpenSUSE LEAP 42.1, and works, and is not yet working on Tumbleweed (2016-November).

```
sudo zypper dup

sudo zypper install libxslt-devel  postgresql postgresql-devel libpqxx-devel redis libicu-devel nodejs npm4 git ed cmake \
         rpm-build gcc-c++ krb5-devel go postgresql-server postgresql-contrib \
         libxml2-devel libxml2-devel-32bit findutils-locate

sudo npm install -g phantomjs
```

Manual fixes required on OpenSUSE LEAP to work around a gem install failure that aborts the gdk install. Apply bundle config option, and if you already ran gdk install and you need to resume it, gdk reconfigure can be helpful. If you haven't run gdk install yet you don't need gdk reconfigure:

```
bundle config build.nokogiri "--use-system-libraries"
gdk reconfigure
```

Manual fix required on OpenSUSE LEAP to place redis-server in the path for non-root users:
```
sudo ln -s /usr/sbin/redis-server /usr/bin/redis-server 
```


### FreeBSD

Please read [the prerequisites for all platforms](#prerequisites-for-all-platforms).

```
sudo pkg install postgresql93-server postgresql93-contrib postgresql-libpqxx \
redis go node icu krb5 phantomjs gmake
```

### Other platforms

If you got GDK running an another platform please send a merge request to add
it here.

## Installation

After you have completed everything here, please procede to [install GDK](doc/set-up-gdk.md)

[puias]: https://gitlab.com/gitlab-org/gitlab-recipes/tree/master/install/centos#add-puias-computational-repository
[docker engine]: https://docs.docker.com/engine/installation/
[vagrant]: https://www.vagrantup.com


