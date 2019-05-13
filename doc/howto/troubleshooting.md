# Troubleshooting

## Rebuilding gems with native extensions

There may be times when your local libraries that are used to build some gems'
native extensions are updated (i.e., `libicu`), thus resulting in errors like:

```shell
rails-background-jobs.1 | /home/user/.rvm/gems/ruby-2.3.0/gems/activesupport-4.2.5.2/lib/active_support/dependencies.rb:274:in 'require': libicudata.so
cannot open shared object file: No such file or directory - /home/user/.rvm/gems/ruby-2.3.0/gems/charlock_holmes-0.7.3/lib/charlock_holmes/charlock_holmes.so (LoadError)
```

```shell
cd /home/user/gitlab-development-kit/gitlab && bundle exec rake gettext:compile > /home/user/gitlab-development-kit/gettext.log 2>&1
make: *** [.gettext] Error 1
```

```shell
rake aborted!
LoadError: dlopen(/home/user/.rbenv/versions/2.6.3/lib/ruby/gems/2.5.0/gems/charlock_holmes-0.7.6/lib/charlock_holmes/charlock_holmes.bundle, 9): Library not loaded: /usr/local/opt/icu4c/lib/libicudata.63.1.dylib
  Referenced from: /home/user/.rbenv/versions/2.6.3/lib/ruby/gems/2.5.0/gems/charlock_holmes-0.7.6/lib/charlock_holmes/charlock_holmes.bundle
  Reason: image not found - /home/user/.rbenv/versions/2.6.3/lib/ruby/gems/2.5.0/gems/charlock_holmes-0.7.6/lib/charlock_holmes/charlock_holmes.bundle
```

In that case, find the offending gem and use `pristine` to rebuild its native
extensions:

```bash
gem pristine charlock_holmes
```

## An error occurred while installing mysql2

```shell
An error occurred while installing mysql2 (0.4.10), and Bundler cannot continue.
Make sure that `gem install mysql2 -v '0.4.10' --source 'https://rubygems.org/'` succeeds before bundling.
```

```shell
Installing mysql2 0.4.10 with native extensions
Gem::Ext::BuildError: ERROR: Failed to build gem native extension.

    current directory: /home/user/.rbenv/versions/2.6.3/lib/ruby/gems/2.6.0/gems/mysql2-0.4.10/ext/mysql2
/home/user/.rbenv/versions/2.6.3/bin/ruby -I /home/user/.rbenv/versions/2.6.3/lib/ruby/2.6.0 -r
./siteconf20190510-96137-15ejlj6.rb extconf.rb --with-ldflags\=-L/usr/local/opt/openssl/lib\
--with-cppflags\=-I/usr/local/opt/openssl/include
checking for rb_absint_size()... *** extconf.rb failed ***
Could not create Makefile due to some reason, probably lack of necessary
libraries and/or headers.  Check the mkmf.log file for more details.  You may
need configuration options.
```

The solution here is:

```shell
bundle config --global build.mysql2 --with-opt-dir="$(brew --prefix openssl)"
```

And running `bundle` again will work.

## `charlock_holmes` `0.7.x` cannot be installed on macOS Sierra

The installation of the `charlock_holmes` gem (`0.7.3` or greater) during
`bundle install` may fail on macOS Sierra with the following error:

```
[SNIPPED]

/usr/local/Cellar/icu4c/59.1/include/unicode/unistr.h:3025:7: error: delegating constructors are permitted only in C++11
    UnicodeString(ConstChar16Ptr(text)) {}
    ^~~~~~~~~~~~~
/usr/local/Cellar/icu4c/59.1/include/unicode/unistr.h:3087:7: error: delegating constructors are permitted only in C++11
    UnicodeString(ConstChar16Ptr(text), length) {}
    ^~~~~~~~~~~~~
/usr/local/Cellar/icu4c/59.1/include/unicode/unistr.h:3180:7: error: delegating constructors are permitted only in C++11
    UnicodeString(Char16Ptr(buffer), buffLength, buffCapacity) {}

[SNIPPED]
```

A working solution is to configure the `--with-cxxflags=-std=c++11` flag
in the Rubygems global build options for this gem:

```
$ bundle config --global build.charlock_holmes "--with-cxxflags=-std=c++11"
$ bundle install
```

The solution can be found at
https://github.com/brianmario/charlock_holmes/issues/117#issuecomment-329798280.

**Note:** If you get installation problems related to `icu4c`, make sure to also
set the `--with-icu-dir=/usr/local/opt/icu4c` option:

```
$ bundle config --global build.charlock_holmes "--with-icu-dir=/usr/local/opt/icu4c --with-cxxflags=-std=c++11"
```

[Gitaly]: https://gitlab.com/gitlab-org/gitaly/blob/14fd3b2e3adae00f0a792516e74a4bac29a5b5c1/Makefile#L58

## `charlock_holmes` `0.7.5` cannot be installed with icu4c 61.1

The installation of the `charlock_holmes` v0.7.5 gem during `bundle install`
may fail with the following error:

```
[SNIPPED]

transliterator.cpp:108:3: error: no template named 'StringByteSink'; did you mean 'icu_61::StringByteSink'?
  StringByteSink<std::string> sink(&result);
  ^~~~~~~~~~~~~~
  icu_61::StringByteSink
/usr/local/include/unicode/bytestream.h:232:7: note: 'icu_61::StringByteSink' declared here
class StringByteSink : public ByteSink {
    ^
transliterator.cpp:106:34: warning: implicit conversion loses integer precision: 'size_t' (aka 'unsigned long') to 'int32_t' (aka 'int') [-Wshorten-64-to-32]
  u_txt = new UnicodeString(txt, txt_len);
            ~~~~~~~~~~~~~      ^~~~~~~
1 warning and 9 errors generated.
make: *** [transliterator.o] Error 1
```

To fix this, you can run:

```
gem install charlock_holmes -v '0.7.5' -- --with-cppflags=-DU_USING_ICU_NAMESPACE=1
```

0.7.6 fixes this issue. See [this issue](https://github.com/brianmario/charlock_holmes/issues/126) for more details.

## Unable to build and install pg gem on gdk run

After installing PostgreSQL with brew you will have to set the proper path to PostgreSQL.
You may run into the following errors on running `gdk run`
```
Gem::Ext::BuildError: ERROR: Failed to build gem native extension.

    current directory: /Users/janedoe/.rvm/gems/ruby-2.3.3/gems/pg-0.18.4/ext
/Users/janedoe/.rvm/rubies/ruby-2.3.3/bin/ruby -r ./siteconf20180330-95521-1k5x76v.rb extconf.rb
checking for pg_config... no
No pg_config... trying anyway. If building fails, please try again with
 --with-pg-config=/path/to/pg_config

 ...

An error occurred while installing pg (0.18.4), and Bundler cannot continue.
Make sure that `gem install pg -v '0.18.4'` succeeds before bundling.

```

This is because the script fails to find the PostgreSQL instance in the path.
The instructions for this may show up after installing PostgreSQL.
The example below is from running `brew install postgresql@9.6` on OS X installation.
For other versions, other platform install and other shell terminal please adjust the path accordingly.

```
If you need to have this software first in your PATH run:
  echo 'export PATH="/usr/local/opt/postgresql@9.6/bin:$PATH"' >> ~/.bash_profile
```

Once this is set, run the `gdk run` command again.

## Error in database migrations when pg_trgm extension is missing

Since GitLab 8.6+ the PostgreSQL extension `pg_trgm` must be installed. If you
are installing GDK for the first time this is handled automatically from the
database schema. In case you are updating your GDK and you experience this
error, make sure you pull the latest changes from the GDK repository and run:

```bash
./support/enable-postgres-extensions
```

## Upgrading PostgreSQL

In case you are hit by `FATAL: database files are incompatible with server`,
you need to upgrade Postgres.

This is what to do when your OS/packaging system decides to install a new minor
version of Postgres:

1. (optional) Downgrade postgres
1. (optional) Make a sql-only GitLab backup
1. Rename/remove the gdk/postgresql/data directory: `mv postgresql/data{,.old}`
1. Run `make`
1. Build pg gem native extensions: `gem pristine pg`
1. (optional) Restore your gitlab backup

If things are working, you may remove the `postgresql/data.old` directory
completely.

## Rails cannot connect to Postgres

- Until [gitlab-ce#54718](https://gitlab.com/gitlab-org/gitlab-ce/issues/54718) is fixed, [comment out](https://gitlab.com/gitlab-org/gitlab-development-kit/issues/420#note_121439593) Sidekiq's reliable fetch initialization.
- Check if foreman is running in the gitlab-development-kit directory.
- Check for custom Postgres connection settings defined via the environment; we
  assume none such variables are set. Look for them with `set | grep '^PG'`.

## undefined symbol: SSLv2_method

This happens if your local OpenSSL library is updated and your Ruby binary is
built against an older version.

If you are using `rvm`, you should reinstall the Ruby binary. The following
command will fetch Ruby 2.3 and install it from source:

```
rvm reinstall --disable-binary 2.3
```

## Fix conflicts in database migrations if you use the same db for CE and EE

>**Note:**
The recommended way to fix the problem is to rebuild your database and move
your EE development into a new directory.

In case you use the same database for both CE and EE development, sometimes you
can get stuck in a situation when the migration is up in `rake db:migrate:status`,
but in reality the database doesn't have it.

For example, https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/3186
introduced some changes when a few EE migrations were added to CE. If you were
using the same db for CE and EE you would get hit by the following error:

```bash
undefined method `share_with_group_lock' for #<Group
```

This exception happened because the system thinks that such migration was
already run, and thus Rails skipped adding the `share_with_group_lock` field to
the `namespaces` table.

The problem is that you can not run `rake db:migrate:up VERSION=xxx` since the
system thinks the migration is already run. Also, you can not run
`rake db:migrate:redo VERSION=xxx` since it tries to do `down` before `up`,
which fails if column does not exist or can cause data loss if column exists.

A quick solution is to remove the database data and then recreate it:

```bash
rm -rf postgresql/data ; make
```

---

If you don't want to nuke the database, you can perform the migrations manually.
Open a terminal and start the rails console:

```bash
rails console
```

And run manually the migrations:

```
require Rails.root.join("db/migrate/20130711063759_create_project_group_links.rb")
CreateProjectGroupLinks.new.change
require Rails.root.join("db/migrate/20130820102832_add_access_to_project_group_link.rb")
AddAccessToProjectGroupLink.new.change
require Rails.root.join("db/migrate/20150930110012_add_group_share_lock.rb")
AddGroupShareLock.new.change
```

You should now be able to continue your development. You might want to note
that in this case we had 3 migrations happening:

```
db/migrate/20130711063759_create_project_group_links.rb
db/migrate/20130820102832_add_access_to_project_group_link.rb
db/migrate/20150930110012_add_group_share_lock.rb
```

In general it doesn't matter in which order you run them, but in this case
the last two migrations create columns in a table which is created by the first
migration. So, in this example the order is important. Otherwise you would try
to create a column in a non-existent table which would of course fail.

## 'LoadError: dlopen' when starting Ruby apps

This can happen when you try to load a Ruby gem with native extensions that
were linked against a system library that is no longer there. A typical culprit
is Homebrew on macOS, which encourages frequent updates (`brew update && brew
upgrade`) which may break binary compatibility.

```
bundle exec rake db:create dev:setup
rake aborted!
LoadError: dlopen(/Users/janedoe/.rbenv/versions/2.1.2/lib/ruby/gems/2.1.0/extensions/x86_64-darwin-13/2.1.0-static/charlock_holmes-0.6.9.4/charlock_holmes/charlock_holmes.bundle, 9): Library not loaded: /usr/local/opt/icu4c/lib/libicui18n.52.1.dylib
  Referenced from: /Users/janedoe/.rbenv/versions/2.1.2/lib/ruby/gems/2.1.0/extensions/x86_64-darwin-13/2.1.0-static/charlock_holmes-0.6.9.4/charlock_holmes/charlock_holmes.bundle
  Reason: image not found - /Users/janedoe/.rbenv/versions/2.1.2/lib/ruby/gems/2.1.0/extensions/x86_64-darwin-13/2.1.0-static/charlock_holmes-0.6.9.4/charlock_holmes/charlock_holmes.bundle
/Users/janedoe/gitlab-development-kit/gitlab/config/application.rb:6:in `<top (required)>'
/Users/janedoe/gitlab-development-kit/gitlab/Rakefile:5:in `require'
/Users/janedoe/gitlab-development-kit/gitlab/Rakefile:5:in `<top (required)>'
(See full trace by running task with --trace)
```

In the above example, you see that the charlock_holmes gem fails to load
`libicui18n.52.1.dylib`. You can try fixing this by [re-installing
charlock_holmes](#rebuilding-gems-with-native-extensions).

## 'bundle install' fails due to permission problems

This can happen if you are using a system-wide Ruby installation. You can
override the Ruby gem install path with `BUNDLE_PATH`:

```
# Install gems in (current directory)/vendor/bundle
make BUNDLE_PATH=$(pwd)/vendor/bundle
```

## 'bundle install' fails while compiling eventmachine gem

On OS X El Capitan, the eventmachine gem compilation might fail with:

```
Gem::Ext::BuildError: ERROR: Failed to build gem native extension.
<snip>
make "DESTDIR=" clean

make "DESTDIR="
compiling binder.cpp
In file included from binder.cpp:20:
./project.h:116:10: fatal error: 'openssl/ssl.h' file not found
#include <openssl/ssl.h>
        ^
1 error generated.
make: *** [binder.o] Error 1

make failed, exit code 2

```

To fix it:

```
bundle config build.eventmachine --with-cppflags=-I/usr/local/opt/openssl/include
```

and then do `bundle install` once again.

## 'Invalid reference name' when creating a new tag

Make sure that `git` is configured correctly on your development
machine (where GDK runs).

```
git checkout -b can-I-commit
git commit --allow-empty -m 'I can commit'
```


## 'gem install nokogiri' fails

Make sure that Xcode Command Line Tools installed on your development machine. For the discussion see this [issue](https://gitlab.com/gitlab-org/gitlab-development-kit/issues/124)

```
brew unlink gcc-4.2      # you might not need this step
gem uninstall nokogiri
xcode-select --install
gem install nokogiri
```

## `gem install gpgme` `2.0.x` fails to compile native extension on macOS Mojave

If building `gpgme` gem fails with an `Undefined symbols for architecture x86_64` error on macOS Mojave, build `gpgme` using system libraries instead.

1. Ensure necessary dependencies are installed:

    ```sh
    brew install gpgme
    ```

1. (optional) Try building the `gpgme` gem manually to ensure it compiles. If it fails, debug the failure with the error messages. To compile the `gpgme` gem manually run:

    ```sh
    gem install gpgme -- --use-system-libraries
    ```

1. Configure Bundler to use system libraries for the `gpgme` gem:

    ```sh
    bundle config build.gpgme --use-system-libraries
    ```

You can now run `gdk install` or `bundle` again.

## LoadError due to readline

On macOS, GitLab may fail to start and fail with an error message about
`libreadline`:

```
LoadError:
    dlopen(/Users/janedoe/.rbenv/versions/2.6.3/lib/ruby/2.5.0/x86_64-darwin15/readline.bundle, 9): Library not loaded: /usr/local/opt/readline/lib/libreadline.7.dylib
        Referenced from: /Users/janedoe/.rbenv/versions/2.6.3/lib/ruby/2.5.0/x86_64-darwin15/readline.bundle
        Reason: image not found - /Users/janedoe/.rbenv/versions/2.6.3/lib/ruby/2.5.0/x86_64-darwin15/readline.bundle
```

This happens because the Ruby interpreter was linked with a version of
the `readline` library that may have been updated on your system. To fix
the error, reinstall the Ruby interpreter. For example, for environments
managed with:

- [rbenv](https://github.com/rbenv/rbenv), run `rbenv install 2.6.3`.
- [RVM](https://rvm.io), run `rvm reinstall ruby-2.6.3`.

## Delete non-existent migrations from the database

If for some reason you end up having database migrations that no longer exist
but are present in your database, you might want to remove them.

1. Find the non-existent migrations with `rake db:migrate:status`. You should
    see some entries like:

    ```
    up     20160727191041  ********** NO FILE **********
    up     20160727193336  ********** NO FILE **********
    ```

1. Open a rails database console with `rails dbconsole`.
1. Delete the migrations you want with:

    ```sql
    DELETE FROM schema_migrations WHERE version='20160727191041';
    ```

You can now run `rake db:migrate:status` again to verify that the entries are
deleted from the database.

## Foreman fails to start

Foreman will fail to start if the `Thor` gem version installed is `0.19.3`
(a foreman dependency), the stacktrace will be:

```
gems/2.3.0/gems/thor-0.19.2/lib/thor/base.rb:534:in `thor_reserved_word?': "run" is a Thor reserved word and cannot be defined as command (RuntimeError)
    from gems/2.3.0/gems/thor-0.19.2/lib/thor/base.rb:597:in `method_added'
    from gems/2.3.0/gems/foreman-0.82.0/lib/foreman/cli.rb:80:in `<class:CLI>'
    from gems/2.3.0/gems/foreman-0.82.0/lib/foreman/cli.rb:11:in `<top (required)>'
    from 2.3.0/rubygems/core_ext/kernel_require.rb:68:in `require'
    from 2.3.0/rubygems/core_ext/kernel_require.rb:68:in `require'
    from gems/2.3.0/gems/foreman-0.82.0/bin/foreman:5:in `<top (required)>'
    from /.../bin/foreman:23:in `load'
    from /.../bin/foreman:23:in `<main>'
```

You can fix this by updating the `Thor` gem.

```
gem update thor
```

## Webpack

Since webpack has been added as a new background process which gitlab depends on
in development, the [GDK must be updated and reconfigured](../update-gdk.md) in
order to work properly again.

If you still encounter some errors, see the troubleshooting FAQ below:

* I'm getting an error when I run `gdk reconfigure`:

    ```
    Makefile:30: recipe for target 'gitlab/config/gitlab.yml' failed
    make: *** [gitlab/config/gitlab.yml] Error 1
    ```

    This is likely because you have not updated your gitlab CE/EE repository to
    the latest master yet.  It has a template for gitlab.yml in it which the GDK
    needs to update.  The `gdk update` step should have taken care of this for
    you, but you can also manually go to your gitlab ce/ee directory and run
    `git checkout master && git pull origin master`

    ---

* I'm getting an error when I attempt to access my local GitLab in a browser:

    ```
    Webpack::Rails::Manifest::ManifestLoadError at /
    Could not load manifest from webpack-dev-server at http://localhost:3808/assets/webpack/manifest.json - is it running, and is stats-webpack-plugin loaded?
    ```

    or

    ```
    Webpack::Rails::Manifest::ManifestLoadError at /
    Could not load compiled manifest from /path/to/gitlab-development-kit/gitlab/public/assets/webpack/manifest.json - have you run `rake webpack:compile`?
    ```

    This probably means that the webpack dev server isn't running or that your
    gitlab.yml isn't properly configured. Ensure that you have run
    `gdk reconfigure` **AND** that you have stopped and restarted any instance
    of `gdk run` or `gdk run xxx` that was running prior to the reconfigure step

    ---

* I'm getting the following error when I try to run `gdk run` or `gdk run db`:

    ```
    09:46:05 webpack.1               | npm ERR! argv "/usr/local/bin/node" "/usr/local/bin/npm" "run" "dev-server"
    09:46:05 webpack.1               | npm ERR! node v5.8.0
    09:46:05 webpack.1               | npm ERR! npm  v3.10.7
    09:46:05 webpack.1               |
    09:46:05 webpack.1               | npm ERR! missing script: dev-server
    ...
    ```

    This means your gitlab CE or EE instance is not running the current master
    branch.  If you are running a branch which hasn't been rebased on master
    since Saturday, Feb 4th then you should rebase it on master.  If you are
    running the master branch, ensure it is up to date (`git pull`).

    ---

* I'm getting the following error when I try to run `gdk run` or `gdk run db`:

    ```
    09:54:15 webpack.1               | > @ dev-server /Users/mike/Projects/gitlab-development-kit/gitlab
    09:54:15 webpack.1               | > webpack-dev-server --config config/webpack.config.js
    09:54:15 webpack.1               |
    09:54:15 webpack.1               | sh: webpack-dev-server: command not found
    09:54:15 webpack.1               |
    ...
    ```

    This means you have not run `npm install` since updating your gitlab CE/EE
    repository.  The `gdk update` command should have done this for you, but you
    can do so manually as well.

* I'm getting the following error when I try to run `gdk run`:

    ```
    14:52:22 webpack.1               | [nodemon] starting `node ./node_modules/.bin/webpack-dev-server --config config/webpack.config.js`
    14:52:22 webpack.1               | events.js:160
    14:52:22 webpack.1               |       throw er; // Unhandled 'error' event
    14:52:22 webpack.1               |       ^
    14:52:22 webpack.1               |
    14:52:22 webpack.1               | Error: listen EADDRINUSE 127.0.0.1:3808
    ...
    ```

    This means the port is already in use, probably because webpack failed to
    terminate correctly when the GDK was last shutdown. You can find out the pid
    of the process using the port with the command `lsof -i :3808`. If you are
    using Vagrant the `lsof` command is not available. Instead you can use the
    command `ss -pntl 'sport = :3808'`. The left over process can be killed with
    the command `kill PID`.

## Testing environment database problems

There may be times when running spinach feature tests or rspec tests
steps such as `sign-up` or `log-out` will fail for no apparent reason.

In that case what you need to do is run the following command inside the gitlab directory:

```
RAILS_ENV=test bundle exec rake db:reset
```

## Windows 10 WSL common issues

* `gdk run db` fails with exit code X

    If you have restarted your computer recently, don't forget to start PostgreSQL server manually; init.d scripts don't work currently as of build 15063.138:

    `sudo service postgresql start`

## Homebrew: Postgres 10.0: "database files are incompatible with server"

```
FATAL:  database files are incompatible with server
DETAIL:  The data directory was initialized by PostgreSQL version 9.6, which is not compatible with this version 10.0.
```

GitLab is not compatible with Postgres 10.0. The following workaround
lets you get back Postgres 9.6. TODO: find a good way to co-exist with
Postgres 10.0 in Homebrew.

```
brew install postgresql@9.6
brew link --force postgresql@9.6
```

## Unicorn timeout

Browser shows `EOF`. Logs show a timeout:

```
error: GET "/users/sign_in": badgateway: failed after 62s: EOF
```

Depending on the performance of your development environment, Unicorn may
time out. Increase the timeout as a workaround.

Edit `gitlab/config/unicorn.rb`:

```
timeout 3600
```

## fatal: not a git repository

If `gdk init` or any other `gdk` command gives you the following error:

```
fatal: not a git repository (or any of the parent directories): .git
```

Make sure you don't have `gdk` aliased in your shell.
For example the git module in [prezto](https://github.com/sorin-ionescu/prezto)
has an [alias](https://github.com/sorin-ionescu/prezto/blob/master/modules/git/README.md#data)
for `gdk` that lists killed files.

## Jaeger Issues

If you're seeing errors such as:

`ERROR -- : Failure while sending a batch of spans: Failed to open TCP connection to localhost:14268 (Connection refused - connect(2) for "localhost" port 14268)`

This is most likely because Jaeger is not configured in your `$GDKROOT/Procfile`.
The easiest way to fix this is by re-creating your `Procfile` and then running
a `gdk reconfigure`:

1. `mv Procfile Procfile.old; make Procfile`
1. `gdk reconfigure`

For more information about Jaeger, visit the [distributed tracing GitLab developer
documentation](https://docs.gitlab.com/ee/development/distributed_tracing.html).

## Other problems

Please open an issue on the [GDK issue tracker](https://gitlab.com/gitlab-org/gitlab-development-kit/issues).
