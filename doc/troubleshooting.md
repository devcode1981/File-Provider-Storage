# Troubleshooting

Before attempting the specific troubleshooting steps documented below, many problems can
be resolved with the following commands run from the GDK project's root directory:

```shell
cd gitlab
yarn install && bundle install
bundle exec rails db:migrate RAILS_ENV=development
```

This installs required Node.js modules and Ruby gems, and performs database migrations,
which can fix errors caused by switching branches.

## Rebuilding gems with native extensions

There may be times when your local libraries that are used to build some gems'
native extensions are updated (i.e., `libicu`), thus resulting in errors like:

```shell
rails-background-jobs.1 | /home/user/.rvm/gems/ruby-2.3.0/gems/activesupport-4.2.5.2/lib/active_support/dependencies.rb:274:in 'require': libicudata.so
cannot open shared object file: No such file or directory - /home/user/.rvm/gems/ruby-2.3.0/gems/charlock_holmes-0.7.3/lib/charlock_holmes/charlock_holmes.so (LoadError)
```

```shell
cd /home/user/gitlab-development-kit/gitlab && bundle exec rake gettext:compile > /home/user/gitlab-development-kit/gitlab/log/gettext.log 2>&1
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

```shell
gem pristine charlock_holmes
```

Or for example `re2` on MacOS:

```shell
/Users/user/gitlab-development-kit/gitlab/lib/gitlab/untrusted_regexp.rb:25:  [BUG] Segmentation fault at 0x0000000000000000
ruby 2.6.6p146 (2020-03-31 revision 67876) [x86_64-darwin19]
```

In which case you would run:

```shell
gem pristine re2
```

## An error occurred while installing gpgme on macOS

Check if you have `gawk` installed >= 5.0.0 and uninstall it.

Re-run the `gdk install` again and follow any on-screen instructions related to installing `gpgme`.

## `charlock_holmes` `0.7.x` cannot be installed on macOS Sierra

The installation of the `charlock_holmes` gem (`0.7.3` or greater) during
`bundle install` may fail on macOS Sierra with the following error:

```plaintext
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
in the Ruby gems global build options for this gem:

```shell
bundle config --global build.charlock_holmes "--with-cxxflags=-std=c++11"
bundle install
```

The solution can be found at
<https://github.com/brianmario/charlock_holmes/issues/117#issuecomment-329798280>.

**Note:** If you get installation problems related to `icu4c`, make sure to also
set the `--with-icu-dir=/usr/local/opt/icu4c` option:

```shell
bundle config --global build.charlock_holmes "--with-icu-dir=/usr/local/opt/icu4c --with-cxxflags=-std=c++11"
```

## `charlock_holmes` `0.7.5` cannot be installed with icu4c 61.1

The installation of the `charlock_holmes` v0.7.5 gem during `bundle install`
may fail with the following error:

```plaintext
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

```shell
gem install charlock_holmes -v '0.7.5' -- --with-cppflags=-DU_USING_ICU_NAMESPACE=1
```

0.7.6 fixes this issue. See [this issue](https://github.com/brianmario/charlock_holmes/issues/126) for more details.

## Unable to build and install `pg` gem on GDK install

After installing PostgreSQL with brew you will have to set the proper path to PostgreSQL.
You may run into the following errors on running `gdk install`

```plaintext
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
The example below is from running `brew install postgresql@10` on OS X installation.
For other versions, other platform install and other shell terminal please adjust the path accordingly.

```plaintext
If you need to have this software first in your PATH run:
  echo 'export PATH="/usr/local/opt/postgresql@10/bin:$PATH"' >> ~/.bash_profile
```

Once this is set, run the `gdk install` command again.

## Error in database migrations when pg_trgm extension is missing

Since GitLab 8.6+ the PostgreSQL extension `pg_trgm` must be installed. If you
are installing GDK for the first time this is handled automatically from the
database schema. In case you are updating your GDK and you experience this
error, make sure you pull the latest changes from the GDK repository and run:

```shell
./support/enable-postgres-extensions
```

## ActiveRecord::PendingMigrationError at /

After running the GitLab Development Kit using `gdk start` and browsing to `http://localhost:3000/`, you may see an error page that says `ActiveRecord::PendingMigrationError at /. Migrations are pending`.

To fix this error, the pending migration must be resolved. Perform the following steps in your terminal:

1. Change to the `gitlab` directory using `cd gitlab`
1. Run the following command to perform the migration: `rails db:migrate RAILS_ENV=development`

Once the operation is complete, refresh the page.

## Error installing node-gyp

node-gyp may fail to build on macOS Catalina installations. Follow [the node-gyp troubleshooting guide](https://github.com/nodejs/node-gyp/blob/master/macOS_Catalina.md).

## Upgrading PostgreSQL

In case you are hit by `FATAL: database files are incompatible with server`,
you need to upgrade PostgreSQL.

This is what to do when your OS/packaging system decides to install a new minor
version of PostgreSQL:

1. (optional) Downgrade PostgreSQL
1. (optional) Make a sql-only GitLab backup
1. Rename/remove the `gdk/postgresql/data` directory: `mv postgresql/data{,.old}`
1. Run `make`
1. Build `pg` gem native extensions: `gem pristine pg`
1. (optional) Restore your GitLab backup

If things are working, you may remove the `postgresql/data.old` directory
completely.

## Rails cannot connect to PostgreSQL

- Use `gdk status` to see if `postgresql` is running.
- Check for custom PostgreSQL connection settings defined via the environment; we
  assume none such variables are set. Look for them with `set | grep '^PG'`.

## undefined symbol: SSLv2_method

This happens if your local OpenSSL library is updated and your Ruby binary is
built against an older version.

If you are using `rvm`, you should reinstall the Ruby binary. The following
command will fetch Ruby 2.3 and install it from source:

```shell
rvm reinstall --disable-binary 2.3
```

## Fix conflicts in database migrations if you use the same db for CE and EE

>**Note:**
The recommended way to fix the problem is to rebuild your database and move
your EE development into a new directory.

In case you use the same database for both CE and EE development, sometimes you
can get stuck in a situation when the migration is up in `rake db:migrate:status`,
but in reality the database doesn't have it.

For example, <https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/3186>
introduced some changes when a few EE migrations were added to CE. If you were
using the same db for CE and EE you would get hit by the following error:

```shell
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

```shell
bundle exec rake setup
```

---

If you don't want to nuke the database, you can perform the migrations manually.
Open a terminal and start the rails console:

```shell
rails console
```

And run manually the migrations:

```plaintext
require Rails.root.join("db/migrate/20130711063759_create_project_group_links.rb")
CreateProjectGroupLinks.new.change
require Rails.root.join("db/migrate/20130820102832_add_access_to_project_group_link.rb")
AddAccessToProjectGroupLink.new.change
require Rails.root.join("db/migrate/20150930110012_add_group_share_lock.rb")
AddGroupShareLock.new.change
```

You should now be able to continue your development. You might want to note
that in this case we had 3 migrations happening:

```plaintext
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

```shell
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

```shell
# Install gems in (current directory)/vendor/bundle
make BUNDLE_PATH=$(pwd)/vendor/bundle
```

## 'bundle install' fails while compiling eventmachine gem

On OS X El Capitan, the eventmachine gem compilation might fail with:

```plaintext
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

```shell
bundle config build.eventmachine --with-cppflags=-I/usr/local/opt/openssl/include
```

and then do `bundle install` once again.

## 'Invalid reference name' when creating a new tag

Make sure that `git` is configured correctly on your development
machine (where GDK runs).

```shell
git checkout -b can-I-commit
git commit --allow-empty -m 'I can commit'
```

## 'gem install nokogiri' fails

Make sure that Xcode Command Line Tools installed on your development machine. For the discussion see
this [issue](https://gitlab.com/gitlab-org/gitlab-development-kit/issues/124).

```shell
brew unlink gcc-4.2      # you might not need this step
gem uninstall nokogiri
xcode-select --install
gem install nokogiri
```

## `gem install gpgme` `2.0.x` fails to compile native extension on macOS Mojave

If building `gpgme` gem fails with an `Undefined symbols for architecture x86_64` error on macOS Mojave, build `gpgme` using system libraries instead.

1. Ensure necessary dependencies are installed:

   ```shell
   brew install gpgme
   ```

1. (optional) Try building the `gpgme` gem manually to ensure it compiles. If it fails, debug the failure with the error messages. To compile the `gpgme` gem manually run:

   ```shell
   gem install gpgme -- --use-system-libraries
   ```

1. Configure Bundler to use system libraries for the `gpgme` gem:

   ```shell
   bundle config build.gpgme --use-system-libraries
   ```

You can now run `gdk install` or `bundle` again.

## `gem install nokogumbo` fails

If you see the following error installing the `nokogumbo` gem via `gdk install`:

```shell

Running 'configure' for libxml2 2.9.9... OK
Running 'compile' for libxml2 2.9.9... ERROR, review
...
sed -e
's?\@XML_LIBDIR\@?-L/Users/erick/Development/gitlab-development-kit/gitlab/-?/gems/nokogiri-1.10.4/ports/x86_64-apple-darwin18.7.0/libxml2/2.9.9/lib?g'
\
-e
's?\@XML_INCLUDEDIR\@?-I/Users/erick/Development/gitlab-development-kit/gitlab/-?/gems/nokogiri-1.10.4/ports/x86_64-apple-darwin18.7.0/libxml2/2.9.9/include/libxml2?g'
\
        -e 's?\@VERSION\@?2.9.9?g' \
        -e 's?\@XML_LIBS\@?-lxml2 -lz -L/usr/local/Cellar/xz/5.2.4/lib -llzma -lpthread  -liconv  -lm ?g' \
           < ./xml2Conf.sh.in > xml2Conf.tmp \
    && mv xml2Conf.tmp xml2Conf.sh
sed: 1: "s?\@XML_LIBDIR\@?-L/Use ...": bad flag in substitute command: '/'
make[3]: *** [xml2Conf.sh] Error 1
make[2]: *** [all-recursive] Error 1
make[1]: *** [all] Error 2
...
An error occurred while installing nokogumbo (1.5.0), and Bundler cannot continue.
Make sure that `gem install nokogumbo -v '1.5.0' --source 'https://rubygems.org/'` succeeds before bundling.

In Gemfile:
  sanitize was resolved to 4.6.6, which depends on
    nokogumbo
make: *** [.gitlab-bundle] Error 5
```

A solution is to:

1. Instruct Bundler to use the system libraries when building `nokogumbo`:

   ```shell
   bundle config build.nokogumbo --use-system-libraries
   ```

1. Re-run `gdk install`

## `gem install ffi` fails

If you see the following error installing the `ffi` gem via `gdk install`:

```shell
Gem::Ext::BuildError: ERROR: Failed to build gem native extension.
...
sed: 1: "s?\@XML_LIBDIR\@?-L/Use ...": bad flag in substitute command: '/'
...
*** extconf.rb failed ***
Could not create Makefile due to some reason, probably lack of necessary
libraries and/or headers.  Check the mkmf.log file for more details.  You may
need configuration options.
...
An error occurred while installing nokogiri (1.10.4), and Bundler cannot continue.
Make sure that `gem install nokogiri -v '1.10.4' --source 'https://rubygems.org/'` succeeds before bundling.
...
compiling AbstractMemory.c
In file included from AbstractMemory.c:47:
In file included from ./AbstractMemory.h:42:
./Types.h:78:10: fatal error: 'ffi.h' file not found
#include <ffi.h>
        ^~~~~~~
1 error generated.
make[1]: *** [AbstractMemory.o] Error 1
...
An error occurred while installing ffi (1.11.1), and Bundler cannot continue.
Make sure that `gem install ffi -v '1.11.1' --source 'https://rubygems.org/'` succeeds before bundling.
```

A solution on macOS is to:

1. Ensure the `PKG_CONFIG_PATH` and `LDFLAGS` environment variables are correctly set:

   ```shell
   export PKG_CONFIG_PATH="$PKG_CONFIG_PATH:$(brew --prefix)/opt/libffi/lib/pkgconfig"
   export LDFLAGS="$LDFLAGS:-L$(brew --prefix)/opt/libffi/lib"
   ```

1. Re-run `gdk install`

## LoadError due to readline

On macOS, GitLab may fail to start and fail with an error message about
`libreadline`:

```plaintext
LoadError:
    dlopen(/Users/janedoe/.rbenv/versions/2.6.3/lib/ruby/2.5.0/x86_64-darwin15/readline.bundle, 9): Library not loaded: /usr/local/opt/readline/lib/libreadline.7.dylib
        Referenced from: /Users/janedoe/.rbenv/versions/2.6.3/lib/ruby/2.5.0/x86_64-darwin15/readline.bundle
        Reason: image not found - /Users/janedoe/.rbenv/versions/2.6.3/lib/ruby/2.5.0/x86_64-darwin15/readline.bundle
```

This happens because the Ruby interpreter was linked with a version of
the `readline` library that may have been updated on your system. To fix
the error, reinstall the Ruby interpreter. For example, for environments
managed with:

- [rbenv](https://github.com/rbenv/rbenv), run `rbenv install 2.6.6`.
- [RVM](https://rvm.io), run `rvm reinstall ruby-2.6.6`.

## Delete non-existent migrations from the database

If for some reason you end up having database migrations that no longer exist
but are present in your database, you might want to remove them.

1. Find the non-existent migrations with `rake db:migrate:status`. You should
   see some entries like:

   ```plaintext
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

## Webpack

Since webpack has been added as a new background process which GitLab depends on
in development, the [GDK must be updated and reconfigured](index.md#update-gdk) in
order to work properly again.

If you still encounter some errors, see the troubleshooting FAQ below:

- I'm getting an error when I run `gdk reconfigure`:

  ```plaintext
  Makefile:30: recipe for target 'gitlab/config/gitlab.yml' failed
  make: *** [gitlab/config/gitlab.yml] Error 1
  ```

  This is likely because you have not updated your GitLab CE/EE repository to
  the latest master yet. It has a template for `gitlab.yml` in it which the GDK
  needs to update. The `gdk update` step should have taken care of this for
  you, but you can also manually go to your GitLab ce/ee directory and run
  `git checkout master && git pull origin master`

    ---

- I'm getting an error when I attempt to access my local GitLab in a browser:

  ```plaintext
  Webpack::Rails::Manifest::ManifestLoadError at /
  Could not load manifest from webpack-dev-server at http://localhost:3808/assets/webpack/manifest.json - is it running, and is stats-webpack-plugin loaded?
  ```

  or

  ```plaintext
  Webpack::Rails::Manifest::ManifestLoadError at /
  Could not load compiled manifest from /path/to/gitlab-development-kit/gitlab/public/assets/webpack/manifest.json - have you run `rake webpack:compile`?
  ```

  This probably means that the webpack dev server isn't running or that your
  `gitlab.yml` isn't properly configured. Ensure that you have run
  `gdk reconfigure` **AND** `gdk restart webpack`.

  ---

- I see the following error when run `gdk tail` or `gdk tail webpack`:

  ```plaintext
  09:46:05 webpack.1               | npm ERR! argv "/usr/local/bin/node" "/usr/local/bin/npm" "run" "dev-server"
  09:46:05 webpack.1               | npm ERR! node v5.8.0
  09:46:05 webpack.1               | npm ERR! npm  v3.10.7
  09:46:05 webpack.1               |
  09:46:05 webpack.1               | npm ERR! missing script: dev-server
  ...
  ```

  This means your GitLab CE or EE instance is not running the current master
  branch. If you are running a branch which hasn't been rebased on master
  since Saturday, Feb 4th then you should rebase it on master. If you are
  running the master branch, ensure it is up to date (`git pull`).

  ---

- I see the following error when run `gdk tail` or `gdk tail webpack`:

  ```plaintext
  09:54:15 webpack.1               | > @ dev-server /Users/mike/Projects/gitlab-development-kit/gitlab
  09:54:15 webpack.1               | > webpack-dev-server --config config/webpack.config.js
  09:54:15 webpack.1               |
  09:54:15 webpack.1               | sh: webpack-dev-server: command not found
  09:54:15 webpack.1               |
  ...
  ```

  This means you have not run `yarn install` since updating your `gitlab/gitlab-foss`
  repository. The `gdk update` command should have done this for you, but you
  can do so manually as well.

- I see the following error when run `gdk tail` or `gdk tail webpack`:

  ```plaintext
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

## Problems with running tests

There may be times when running spinach feature tests or Ruby Capybara RSpec
tests (tests that are located in the `spec/features` directory) will fail.

### ChromeDriver problems

ChromeDriver is the app on your machine that is used to run headless
browser tests.

If you see this error in your test output (you may need to scroll up):
`Selenium::WebDriver::Error::SessionNotCreatedError` coupled with the
error message: `This version of ChromeDriver only supports Chrome
version [...]` then you need to update your version of ChromeDriver:

If you installed ChromeDriver with Homebrew, then you can update by
running:

```shell
brew cask upgrade chromedriver
```

Otherwise, if you installed the ChromeDriver without Homebrew, you may
need to
[download and install the latest ChromeDrive directly](https://sites.google.com/a/chromium.org/chromedriver/downloads).

### Database problems

Another issue can be that your test environment's database schema has
diverged from what the GitLab app expects. This can happen if you tested
a branch locally that changed the database in some way, and have now
switched back to `master` without
[rolling back](https://edgeguides.rubyonrails.org/active_record_migrations.html#rolling-back)
the migrations locally first.

In that case, what you need to do is run the following command inside
the `gitlab` directory to drop all tables on your test database and have
them recreated from the canonical version in `db/structure.sql`. Note,
dropping and recreating your test database tables is perfectly safe!

```shell
cd gitlab
bundle exec rake db:test:prepare
```

## Windows 10 WSL common issues

- `gdk run db` fails with exit code X

  If you have restarted your computer recently, don't forget to start PostgreSQL server manually; init.d scripts don't work currently as of build 15063.138:

  `sudo service postgresql start`

## Homebrew: PostgreSQL 10.0: "database files are incompatible with server"

```plaintext
FATAL:  database files are incompatible with server
DETAIL:  The data directory was initialized by PostgreSQL version 9.6, which is not compatible with this version 10.0.
```

GitLab is not compatible with PostgreSQL 10.0. The following workaround
lets you get back PostgreSQL 9.6. TODO: find a good way to co-exist with
PostgreSQL 10.0 in Homebrew.

```shell
brew install postgresql@9.6
brew link --force postgresql@9.6
```

## Puma/Unicorn timeout

Browser shows `EOF`. Logs show a timeout:

```plaintext
error: GET "/users/sign_in": badgateway: failed after 62s: EOF
```

Depending on the performance of your development environment, Puma/Unicorn may
time out. Increase the timeout as a workaround.

For Puma: you can use environment variables to override the default timeout:

Variable | Type | Description
-------- | ---- | -----------
`GITLAB_RAILS_RACK_TIMEOUT` | integer | Sets `service_timeout`
`GITLAB_RAILS_WAIT_TIMEOUT` | integer | Sets `wait_timeout`

For Unicorn: edit `gitlab/config/unicorn.rb`:

```ruby
timeout 3600
```

## `fatal: not a git repository`

If `gdk init` or any other `gdk` command gives you the following error:

```plaintext
fatal: not a git repository (or any of the parent directories): .git
```

Make sure you don't have `gdk` aliased in your shell.
For example the Git module in [prezto](https://github.com/sorin-ionescu/prezto)
has an [alias](https://github.com/sorin-ionescu/prezto/blob/master/modules/git/README.md#data)
for `gdk` that lists killed files.

## Problems with Sidekiq (Cluster)

GDK uses Sidekiq Cluster (running a single Sidekiq process) by default instead
`bundle exec sidekiq` directly, which is a step towards making development a
bit more like production.

Technically, running Sidekiq Cluster with a single Sidekiq process matches the same behavior
of running Sidekiq directly, but eventually problems may arise.

If you're experiencing performance issues or jobs not being picked up, try disabling
Sidekiq Cluster by:

1. First stopping all running processes with `gdk stop`
1. Going to `$GDKROOT/Procfile`
1. Removing the `SIDEKIQ_WORKERS` environment variable from `rails-background-jobs`
1. Booting GDK again with `gdk start`

When doing so, please create an issue describing what happened.

## Jaeger Issues

If you're seeing errors such as:

```shell
ERROR -- : Failure while sending a batch of spans: Failed to open TCP connection to localhost:14268 (Connection refused - connect(2) for "localhost" port 14268)
```

This is most likely because Jaeger is not configured in your `$GDKROOT/Procfile`.
The easiest way to fix this is by re-creating your `Procfile` and then running
a `gdk reconfigure`:

1. `mv Procfile Procfile.old; make Procfile`
1. `gdk reconfigure`

For more information about Jaeger, visit the [distributed tracing GitLab developer
documentation](https://docs.gitlab.com/ee/development/distributed_tracing.html).

## Gitaly `config.toml: no such file or directory`

If you see errors such as:

```shell
07:23:16 gitaly.1                | time="2019-05-17T07:23:16-05:00" level=fatal msg="load config" config_path=<path-to-gdk>/gitaly/gitaly.config.toml error="open <path-to-gdk>/gitaly/gitaly.config.toml: no such file or directory"
```

Somehow, `gitaly/gitaly.config.toml` is missing. You can re-create this file by running
the following in your GDK directory:

```shell
make gitaly-setup
```

## Elasticsearch

Running a spec locally may give you something like the following:

```shell
rake aborted!
Gitlab::TaskFailedError: # pkg-config --cflags  -- icu-i18n icu-i18n
Package icu-i18n was not found in the pkg-config search path.
Perhaps you should add the directory containing `icu-i18n.pc'
to the PKG_CONFIG_PATH environment variable
No package 'icu-i18n' found
Package icu-i18n was not found in the pkg-config search path.
Perhaps you should add the directory containing `icu-i18n.pc'
to the PKG_CONFIG_PATH environment variable
No package 'icu-i18n' found
pkg-config: exit status 1
make: *** [build] Error 2
```

This indicates that Go is trying to link (unsuccessfully) to brew's `icu4c`.

Find the directory where `icu-i18n.pc` resides:

- On macOS, using [Homebrew](https://brew.sh/), it is generally in `/usr/local/opt/icu4c/lib/pkgconfig`
- On Ubuntu/Debian it might be in `/usr/lib/x86_64-linux-gnu/pkgconfig`
- On Fedora it is expected to be in `/usr/lib64/pkgconfig`

You'll need to add that directory to the `PKG_CONFIG_PATH` environment variable.

To fix this now, run the following on the command line:

```shell
export PKG_CONFIG_PATH="/usr/local/opt/icu4c/lib/pkgconfig:$PKG_CONFIG_PATH"
```

To fix this for the future, add the line above to `~/.bash_profile` or `~/.zshrc`.

### Elasticsearch indexer looks for the wrong version of icu4c

You might get the following error when updating the application:

```plaintext
# gitlab.com/gitlab-org/gitlab-elasticsearch-indexer
/usr/local/Cellar/go/1.14.2_1/libexec/pkg/tool/darwin_amd64/link: running clang failed: exit status 1
ld: warning: directory not found for option '-L/usr/local/Cellar/icu4c/64.2/lib'
ld: library not found for -licui18n
clang: error: linker command failed with exit code 1 (use -v to see invocation)

make[1]: *** [build] Error 2
make: *** [gitlab-elasticsearch-indexer/bin/gitlab-elasticsearch-indexer] Error 2
```

This means Go is trying to link to brew's version of `icu4c` (`64.2` in the example), and failing.
This can happen when `icu4c` is not pinned and got updated. Verify the version with:

```shell
$ ls /usr/local/Cellar/icu4c
66.1
```

Clean Go's cache to fix this error. From the GDK's root directory:

```shell
cd gitlab-elasticsearch-indexer/
go clean -cache
```

## Failures when generating Karma fixtures

In some cases, running `bin/rake karma:fixtures` might fail to generate some fixtures, you'll see this kind of errors in the console:

```plaintext
Failed examples:

rspec ./spec/javascripts/fixtures/blob.rb:25 # Projects::BlobController (JavaScript fixtures) blob/show.html
rspec ./spec/javascripts/fixtures/branches.rb:24 # Projects::BranchesController (JavaScript fixtures) branches/new_branch.html
rspec ./spec/javascripts/fixtures/commit.rb:22 # Projects::CommitController (JavaScript fixtures) commit/show.html
```

To fix this, remove `tmp/tests/` in the `gitlab/` directory and regenerate the fixtures:

```shell
rm -rf tmp/tests/ && bin/rake karma:fixtures
```

## yarn: error: no such option: --pure-lockfile

The full error you might be getting is:

```plaintext
Makefile:134: recipe for target '.gitlab-yarn' failed
make: *** [.gitlab-yarn] Error 2
```

This is likely to happen if you installed `yarn` using `apt install cmdtest`.

To fix this, install yarn using npm instead:

```shell
npm install --global yarn
```

## Homebrew troubleshooting

Most `brew` problems can be sniffed out by running

```shell
brew doctor
```

However, older installations may have significant cruft leftover from previous
installations and updates. To manually remove outdated downloads for all
formulae, casks, and stale lockfiles, run:

```shell
brew cleanup
```

For more information on uninstalling old versions of a formula, see the [Homebrew FAQ](https://docs.brew.sh/FAQ#how-do-i-uninstall-old-versions-of-a-formula).
For additional troubleshooting information, see the Homebrew [Common Issues](https://docs.brew.sh/Common-Issues) page.

## CSS isn't live reloading

If you previously compiled production assets with `bundle exec rake gitlab:assets:compile`, the GDK
serves the assets from the `public/assets/` directory, which means that changing SCSS files won't
have any effect in development until you re-compile the assets manually. To re-enable live-reloading
of CSS in development, remove the `public/assets/` directory and restart the GDK.

## Other problems

Please open an issue on the [GDK issue tracker](https://gitlab.com/gitlab-org/gitlab-development-kit/issues).
