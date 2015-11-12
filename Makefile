gitlab_repo = https://gitlab.com/gitlab-org/gitlab-ce.git
gitlab_shell_repo = https://gitlab.com/gitlab-org/gitlab-shell.git
gitlab_runner_repo = https://gitlab.com/gitlab-org/gitlab-ci-runner.git
gitlab_workhorse_repo = https://gitlab.com/gitlab-org/gitlab-workhorse.git
gitlab_development_root = $(shell pwd)
postgres_bin_dir = $(shell pg_config --bindir)

all: gitlab-setup gitlab-shell-setup gitlab-runner-setup gitlab-workhorse-setup nginx-setup support-setup

# Set up the GitLab Rails app

gitlab-setup: gitlab/.git gitlab-config gitlab/.bundle

gitlab/.git:
	git clone ${gitlab_repo} gitlab

gitlab-config: gitlab/config/gitlab.yml gitlab/config/database.yml gitlab/config/unicorn.rb gitlab/config/resque.yml

gitlab/config/gitlab.yml:
	sed -e "s|/home/git|${gitlab_development_root}|"\
	 gitlab/config/gitlab.yml.example > gitlab/config/gitlab.yml
	support/edit-gitlab.yml gitlab/config/gitlab.yml

gitlab/config/database.yml:
	sed "s|/home/git|${gitlab_development_root}|" database.yml.example > gitlab/config/database.yml

gitlab/config/unicorn.rb:
	cp gitlab/config/unicorn.rb.example.development gitlab/config/unicorn.rb
	echo "listen '${gitlab_development_root}/gitlab.socket'" >> $@
	echo "listen '127.0.0.1:8080'" >> $@

gitlab/config/resque.yml:
	sed "s|/home/git|${gitlab_development_root}|" redis/resque.yml.example > $@

gitlab/.bundle:
	cd ${gitlab_development_root}/gitlab && bundle install --without mysql production --jobs 4

# Set up gitlab-shell

gitlab-shell-setup: gitlab-shell/.git gitlab-shell/config.yml gitlab-shell/.bundle

gitlab-shell/.git:
	git clone ${gitlab_shell_repo} gitlab-shell

gitlab-shell/config.yml:
	sed -e "s|/home/git|${gitlab_development_root}|"\
	  -e "s|:8080/|:3000|"\
	  -e "s|/usr/bin/redis-cli|$(shell which redis-cli)|"\
	  -e "s|^  socket: .*|  socket: ${gitlab_development_root}/redis/redis.socket|"\
	  gitlab-shell/config.yml.example > gitlab-shell/config.yml

gitlab-shell/.bundle:
	cd ${gitlab_development_root}/gitlab-shell && bundle install --without production --jobs 4

# Set up gitlab-runner
gitlab-runner-setup: gitlab-runner/.git gitlab-runner/.bundle

gitlab-runner/.git:
	git clone ${gitlab_runner_repo} gitlab-runner

gitlab-runner/.bundle:
	cd ${gitlab_development_root}/gitlab-runner && bundle install --jobs 4

gitlab-runner-clean:
	rm -rf gitlab-runner

# Update gitlab, gitlab-shell and gitlab-runner

update: gitlab-update gitlab-shell-update gitlab-runner-update

gitlab-update: gitlab/.git/pull
	cd ${gitlab_development_root}/gitlab && \
	bundle install --without mysql production --jobs 4 && \
	bundle exec rake db:migrate

gitlab-shell-update: gitlab-shell/.git/pull
	cd ${gitlab_development_root}/gitlab-shell && \
	bundle install --without production --jobs 4

gitlab-runner-update: gitlab-runner/.git/pull
	cd ${gitlab_development_root}/gitlab-runner && \
	bundle install

gitlab/.git/pull:
	cd ${gitlab_development_root}/gitlab && \
		git checkout -- Gemfile.lock db/schema.rb && \
		git stash && git checkout master && \
		git pull --ff-only

gitlab-shell/.git/pull:
	cd ${gitlab_development_root}/gitlab-shell && \
		git stash && git checkout master && \
		git pull --ff-only

gitlab-runner/.git/pull:
	cd ${gitlab_development_root}/gitlab-runner && git pull --ff-only

# Set up supporting services

support-setup: Procfile redis postgresql .bundle
	@echo ""
	@echo "*********************************************"
	@echo "************** Setup finished! **************"
	@echo "*********************************************"
	sed -n '/^## Post-installation/,/^END Post-installation/p' README.md
	@echo "*********************************************"

Procfile:
	sed -e "s|/home/git|${gitlab_development_root}|g"\
	  -e "s|postgres |${postgres_bin_dir}/postgres |"\
	  $@.example > $@

redis: redis/redis.conf

redis/redis.conf:
	sed "s|/home/git|${gitlab_development_root}|" $@.example > $@

postgresql: postgresql/data/PG_VERSION

postgresql/data/PG_VERSION:
	${postgres_bin_dir}/initdb --locale=C -E utf-8 postgresql/data

.bundle:
	bundle install --jobs 4

gitlab-workhorse-setup: gitlab-workhorse/gitlab-workhorse

gitlab-workhorse/gitlab-workhorse: gitlab-workhorse/.git
	cd gitlab-workhorse && make

gitlab-workhorse/.git:
	git clone ${gitlab_workhorse_repo} gitlab-workhorse

nginx-setup: nginx/conf/nginx.conf nginx/logs nginx/tmp

nginx/conf/nginx.conf:
	sed -e "s|/home/git|${gitlab_development_root}|" nginx/conf/nginx.conf.example > $@

nginx/logs:
	mkdir -p $@

nginx/tmp:
	mkdir -p $@

clean-config:
	rm -f \
	gitlab/config/gitlab.yml \
	gitlab/config/database.yml \
	gitlab/config/unicorn.rb \
	gitlab/config/resque.yml \
	gitlab-shell/config.yml \
	redis/redis.conf \
	Procfile \
	nginx/conf/nginx.conf
