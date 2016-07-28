# GitLab with MySQL

Eventhough our prefered database is PostgeSQL, there are time you'd want to test your code on MySQL. This is meant as a general guideline in setting things up.

## Installing MySQL

On OSX, with brew installed run

```
brew install mysql
```

If you've already done this before, run 

```
brew info mysql
```

Both command will print the post install messages on how to start the server. If you're not exposing your development machine to the internet and _only_ use it for development there is no need to to secure your installation.

## Setting up Rails to connect to MySQL

If you ran `bundle install` before, or you've fully installed the GitLab Development Kit, the mysql gem was. To make sure the gem will be installed, remove `mysql` in `gitlab/.bundle/config` from the `BUNDLE_WITHOUT` key. Run `bundle` in the `gitlab` folder to install mysql.

Configuration of the database is stored in `gitlab/config/database.yml`. Run the following command to update it:

```
sed -e 's/^  (username|password)/  # \1/' config/database.yml.mysql > config/database.yml
```

Now you can run `rake dev:setup` and test your code using MySQL for data persistance.

## Reverting back to PostgreSQL for development

In the GDK root:

```
rm gitlab/config/database.yml
make
```
