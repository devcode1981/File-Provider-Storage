# Troubleshooting

## Rebuilding gems with native extensions

There may be times when your local libraries that are used to build some gems'
native extensions are updated (i.e., `libicu`), thus resulting in errors like:

```
rails-background-jobs.1 | /home/user/.rvm/gems/ruby-2.3.0/gems/activesupport-4.2.5.2/lib/active_support/dependencies.rb:274:in 'require': libicudata.so
cannot open shared object file: No such file or directory - /home/user/.rvm/gems/ruby-2.3.0/gems/charlock_holmes-0.7.3/lib/charlock_holmes/charlock_holmes.so (LoadError)
```

In that case, find the offending gem and use `pristine` to rebuild its native
extensions:

```bash
gem pristine charlock_holmes
```

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
`libicui18n.52.1.dylib`. You can try fixing this by re-installing
charlock_holmes:

```
# in /Users/janedoe/gitlab-development-kit
gem uninstall charlock_holmes
bundle install # should reinstall charlock_holmes
```

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

## Other problems

Please open an issue on the [GDK issue tracker](https://gitlab.com/gitlab-org/gitlab-development-kit/issues).
