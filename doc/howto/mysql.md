# GitLab development with MySQL

Even though our prefered database is PostgeSQL, there are time you'd want to test your code on MySQL. This is meant as a general guideline in setting things up.

## Installing MySQL

On OSX, with brew installed run

```
brew install mysql
```

If you've already done this before, run

```
brew info mysql
```

Both commands will print the post install messages on how to start the server. If you're not exposing your development machine to the internet and _only_ use it for development there is no need to to secure your installation.

## Starting MySQL server

You can start a MySQL server by running `mysqld` in your command line.
Gitlab Development Kit does not manage the MySQL server for you.

## Setting up Rails to connect to MySQL

Ensure the `mysql` server is installed. If you ran `gdk update`
before, and did not have it installed at the time, the `mysql` gem
will not be installed.

To make sure the gem is be installed, run `gdk update` again after the
`mysql` server is installed. This will remove `mysql` from
`BUNDLE_WITHOUT` in `gitlab/.bundle/config`.

Configuration of the database is stored in
`gitlab/config/database.yml`. The following command will overwrite
your current database settings with settings for MySQL.

```
sed -e '/username:/d' -e '/password:/d' gitlab/config/database.yml.mysql > gitlab/config/database.yml
```

Now you can run `rake dev:setup` and test your code using MySQL for data persistance.

## Reverting back to PostgreSQL for development

In the GDK root:

```
rm gitlab/config/database.yml
make
```
