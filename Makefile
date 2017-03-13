gitlab_repo = https://gitlab.com/gitlab-org/gitlab-ce.git
gitlab_shell_repo = https://gitlab.com/gitlab-org/gitlab-shell.git
gitlab_workhorse_repo = https://gitlab.com/gitlab-org/gitlab-workhorse.git
gitlab_workhorse_clone_dir = gitlab-workhorse/src/gitlab.com/gitlab-org/gitlab-workhorse
gitaly_repo = https://gitlab.com/gitlab-org/gitaly.git
gitaly_clone_dir = gitaly/src/gitlab.com/gitlab-org/gitaly
gitlab_development_root = $(shell pwd)
postgres_bin_dir = $(shell pg_config --bindir)
postgres_replication_user = gitlab_replication
postgres_dir = $(realpath ./postgresql)
postgres_replica_dir = $(realpath ./postgresql-replica)
port = $(shell cat port 2>/dev/null)
username = $(shell whoami)
sshd_bin = $(shell which sshd)
git_bin = $(shell which git)
webpack_port = $(shell cat webpack_port 2>/dev/null || echo '3808')

all: gitlab-setup gitlab-shell-setup gitlab-workhorse-setup support-setup gitaly-setup

# Set up the GitLab Rails app

gitlab-setup: gitlab/.git gitlab-config bundler .gitlab-bundle .gitlab-npm

gitlab/.git:
	git clone ${gitlab_repo} gitlab

gitlab-config: gitlab/config/gitlab.yml gitlab/config/database.yml gitlab/config/unicorn.rb gitlab/config/resque.yml gitlab/public/uploads

gitlab/config/gitlab.yml:
	sed -e "s|/home/git|${gitlab_development_root}|"\
	  -e "s|/usr/bin/git|${git_bin}|"\
	  gitlab/config/gitlab.yml.example > gitlab/config/gitlab.yml
	port=${port} webpack_port=${webpack_port} support/edit-gitlab.yml gitlab/config/gitlab.yml

gitlab/config/database.yml:
	sed "s|/home/git|${gitlab_development_root}|" database.yml.example > gitlab/config/database.yml

gitlab/config/unicorn.rb:
	cp gitlab/config/unicorn.rb.example.development gitlab/config/unicorn.rb
	echo "listen '${gitlab_development_root}/gitlab.socket'" >> $@

gitlab/config/resque.yml:
	sed "s|/home/git|${gitlab_development_root}|" redis/resque.yml.example > $@

gitlab/public/uploads:
	mkdir $@

.gitlab-bundle:
	cd ${gitlab_development_root}/gitlab && bundle install --without mysql production --jobs 4
	touch $@

.gitlab-npm:
	cd ${gitlab_development_root}/gitlab && npm install
	touch $@

.PHONY:	bundler
bundler:
	command -v $@ > /dev/null || gem install $@

# Set up gitlab-shell

gitlab-shell-setup: gitlab-shell/.git gitlab-shell/config.yml bundler .gitlab-shell-bundle gitlab-shell/.gitlab_shell_secret

gitlab-shell/.git:
	git clone ${gitlab_shell_repo} gitlab-shell

gitlab-shell/config.yml:
	sed -e "s|/home/git|${gitlab_development_root}|"\
	  -e "s|^gitlab_url:.*|gitlab_url: http+unix://${shell echo ${gitlab_development_root}/gitlab.socket | sed 's|/|%2F|g'}|"\
	  -e "s|/usr/bin/redis-cli|$(shell which redis-cli)|"\
	  -e "s|^  socket: .*|  socket: ${gitlab_development_root}/redis/redis.socket|"\
	  gitlab-shell/config.yml.example > gitlab-shell/config.yml

.gitlab-shell-bundle:
	cd ${gitlab_development_root}/gitlab-shell && bundle install --without production --jobs 4
	touch $@

gitlab-shell/.gitlab_shell_secret:
	ln -s ${gitlab_development_root}/gitlab/.gitlab_shell_secret $@

# Set up gitaly

gitaly-setup: gitaly/bin/gitaly

${gitaly_clone_dir}/.git:
	git clone ${gitaly_repo} ${gitaly_clone_dir}

# Update gitlab, gitlab-shell, gitlab-workhorse and gitaly

update: unlock-dependency-installers gitlab-update gitlab-shell-update gitlab-workhorse-update gitaly-update

gitlab-update: gitlab/.git/pull gitlab-setup
	@echo ""
	@echo "------------------------------------------------------------"
	@echo "Make sure Postgres is running otherwise db:migrate will fail"
	@echo "------------------------------------------------------------"
	@echo ""
	cd ${gitlab_development_root}/gitlab && \
		bundle exec rake db:migrate db:test:prepare
	cd ${gitlab_development_root}/gitlab && npm prune

gitlab-shell-update: gitlab-shell/.git/pull gitlab-shell-setup

gitlab/.git/pull:
	cd ${gitlab_development_root}/gitlab && \
		git checkout -- Gemfile.lock db/schema.rb && \
		git stash && git checkout master && \
		git pull --ff-only

gitlab-shell/.git/pull:
	cd ${gitlab_development_root}/gitlab-shell && \
		git stash && git checkout master && \
		git pull --ff-only

gitaly-update: ${gitaly_clone_dir}/.git gitaly/.git/pull gitaly-clean gitaly/bin/gitaly

gitaly/.git/pull:
	cd ${gitaly_clone_dir} && \
		git stash && git checkout master && \
		git pull --ff-only

gitaly-clean:
	rm -rf gitaly/bin

.PHONY:	gitaly/bin/gitaly
gitaly/bin/gitaly:	${gitaly_clone_dir}/.git
	GO15VENDOREXPERIMENT=1 GOPATH=${gitlab_development_root}/gitaly go install gitlab.com/gitlab-org/gitaly/cmd/...

# Set up supporting services

support-setup: .ruby-version foreman Procfile redis postgresql openssh-setup nginx-setup
	@echo ""
	@echo "*********************************************"
	@echo "************** Setup finished! **************"
	@echo "*********************************************"
	cat HELP
	@echo "*********************************************"

Procfile:
	sed -e "s|/home/git|${gitlab_development_root}|g"\
		-e "s|/usr/sbin/sshd|${sshd_bin}|"\
		-e "s|postgres |${postgres_bin_dir}/postgres |"\
		-e "s|DEV_SERVER_PORT=3808 |DEV_SERVER_PORT=${webpack_port} |"\
		$@.example > $@
	if [ -f .vagrant_enabled ]; then \
		echo "0.0.0.0" > host; \
		echo "3000" > port; \
	fi

redis: redis/redis.conf

redis/redis.conf:
	sed "s|/home/git|${gitlab_development_root}|" $@.example > $@

postgresql: postgresql/data

postgresql/data:
	${postgres_bin_dir}/initdb --locale=C -E utf-8 postgresql/data
	support/bootstrap-rails

postgresql-replication/cluster:
	${postgres_bin_dir}/initdb --locale=C -E utf-8 postgresql-replica/data
	cat support/pg_hba.conf.add >> postgresql/data/pg_hba.conf

postgresql-replication/role:
	${postgres_bin_dir}/psql -h ${postgres_dir} -d postgres -c "CREATE ROLE ${postgres_replication_user} WITH REPLICATION LOGIN;"

postgresql-replication/backup:
	psql -h ${postgres_dir} -d postgres -c "select pg_start_backup('base backup for streaming rep')"
	rsync -cva --inplace --exclude="*pg_xlog*" postgresql/data postgresql-replica
	psql -h ${postgres_dir} -d postgres -c "select pg_stop_backup(), current_timestamp"
	./support/recovery.conf ${postgres_dir} > postgresql-replica/data/recovery.conf

.PHONY:	foreman
foreman:
	command -v $@ > /dev/null || gem install $@

.ruby-version:
	ln -s ${gitlab_development_root}/gitlab/.ruby-version $@

localhost.crt:	localhost.key

localhost.key:
	openssl req -new -subj "/CN=localhost/" -x509 -days 365 -newkey rsa:2048 -nodes -keyout "localhost.key" -out "localhost.crt"
	chmod 600 $@

gitlab-workhorse-setup: gitlab-workhorse/bin/gitlab-workhorse gitlab-workhorse/config.toml

gitlab-workhorse/config.toml:
	sed "s|/home/git|${gitlab_development_root}|" $@.example > $@

gitlab-workhorse-update:	${gitlab_workhorse_clone_dir}/.git gitlab-workhorse/.git/pull gitlab-workhorse-clean-bin gitlab-workhorse/bin/gitlab-workhorse

gitlab-workhorse-clean-bin:
	rm -rf gitlab-workhorse/bin

.PHONY:	gitlab-workhorse/bin/gitlab-workhorse
gitlab-workhorse/bin/gitlab-workhorse: ${gitlab_workhorse_clone_dir}/.git
	GO15VENDOREXPERIMENT=1 GOPATH=${gitlab_development_root}/gitlab-workhorse go install gitlab.com/gitlab-org/gitlab-workhorse/...

${gitlab_workhorse_clone_dir}/.git:
	git clone ${gitlab_workhorse_repo} ${gitlab_workhorse_clone_dir}

gitlab-workhorse/.git/pull:
	cd ${gitlab_workhorse_clone_dir} && \
		git stash &&\
		git checkout master &&\
		git pull --ff-only

influxdb-setup:	influxdb/influxdb.conf influxdb/bin/influxd influxdb/meta/meta.db

influxdb/bin/influxd:
	cd influxdb && ${MAKE}

influxdb/meta/meta.db:	Procfile
	grep '^influxdb:' Procfile || (printf ',s/^#influxdb/influxdb/\nwq\n' | ed -s Procfile)
	support/bootstrap-influxdb 8086

influxdb/influxdb.conf:
	sed -e "s|/home/git|${gitlab_development_root}|g" $@.example > $@

grafana-setup:	grafana/grafana.ini grafana/bin/grafana-server grafana/gdk-pg-created grafana/gdk-data-source-created

grafana/bin/grafana-server:
	cd grafana && ${MAKE}

grafana/grafana.ini:
	sed -e "s|/home/git|${gitlab_development_root}|g" \
		-e "s/GDK_USERNAME/${username}/g" \
		$@.example > $@

grafana/gdk-pg-created:
	PATH=${postgres_bin_dir}:${PATH} support/create-grafana-db
	touch $@

grafana/gdk-data-source-created:
	grep '^grafana:' Procfile || (printf ',s/^#grafana/grafana/\nwq\n' | ed -s Procfile)
	support/bootstrap-grafana
	touch $@

performance-metrics-setup:	Procfile influxdb-setup grafana-setup

openssh-setup:	openssh/sshd_config openssh/ssh_host_rsa_key

openssh/sshd_config:
	sed -e "s|/home/git|${gitlab_development_root}|g" \
		-e "s/GDK_USERNAME/${username}/g" \
		$@.example > $@

openssh/ssh_host_rsa_key:
	ssh-keygen -f $@ -N '' -t rsa

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
	gitlab-shell/.gitlab_shell_secret \
	redis/redis.conf \
	.ruby-version \
	Procfile \

unlock-dependency-installers:
	rm -f .gitlab-npm \
	.gitlab-bundle \
	.gitlab-shell-bundle \
