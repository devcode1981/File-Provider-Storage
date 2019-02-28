.NOTPARALLEL:

-include env.mk

gitlab_repo = https://gitlab.com/gitlab-org/gitlab-ce.git
gitlab_repo_base = $(basename ${gitlab_repo})
gitlab_repo_ruby_version = $(shell curl -s "${gitlab_repo_base}/raw/master/.ruby-version")
gitlab_shell_repo = https://gitlab.com/gitlab-org/gitlab-shell.git
gitlab_shell_clone_dir = go-gitlab-shell/src/gitlab.com/gitlab-org/gitlab-shell
gitlab_workhorse_repo = https://gitlab.com/gitlab-org/gitlab-workhorse.git
gitlab_workhorse_clone_dir = gitlab-workhorse/src/gitlab.com/gitlab-org/gitlab-workhorse
gitaly_repo = https://gitlab.com/gitlab-org/gitaly.git
gitaly_proto_repo = https://gitlab.com/gitlab-org/gitaly-proto.git
gitaly_gopath = $(abspath ./gitaly)
gitaly_clone_dir = ${gitaly_gopath}/src/gitlab.com/gitlab-org/gitaly
gitaly_proto_clone_dir = ${gitaly_gopath}/src/gitlab.com/gitlab-org/gitaly-proto
gitlab_pages_repo = https://gitlab.com/gitlab-org/gitlab-pages.git
gitlab_pages_clone_dir = gitlab-pages/src/gitlab.com/gitlab-org/gitlab-pages
gitlab_docs_repo = https://gitlab.com/gitlab-com/gitlab-docs.git
gitlab_development_root = $(shell pwd)
gitaly_assembly_dir = ${gitlab_development_root}/gitaly/assembly
postgres_bin_dir ?= $(shell ruby support/pg_bindir)
postgres_replication_user = gitlab_replication
postgres_dir = $(abspath ./postgresql)
postgres_replica_dir = $(abspath ./postgresql-replica)
postgres_geo_dir = $(abspath ./postgresql-geo)
postgres_data_dir = ${postgres_dir}/data
hostname = $(shell cat hostname 2>/dev/null || echo 'localhost')
port = $(shell cat port 2>/dev/null || echo '3000')
https = $(shell cat https_enabled 2>/dev/null || echo 'false')
relative_url_root = $(shell cat relative_url_root 2>/dev/null || echo '')
username = $(shell whoami)
sshd_bin = $(shell which sshd)
git_bin = $(shell which git)
webpack_port = $(shell cat webpack_port 2>/dev/null || echo '3808')
registry_enabled = $(shell cat registry_enabled 2>/dev/null || echo 'false')
registry_host = $(shell cat registry_host 2>/dev/null || echo '127.0.0.1')
registry_external_port = $(shell cat registry_external_port 2>/dev/null || echo '5000')
registry_port = $(shell cat registry_port 2>/dev/null || echo '5000')
gitlab_from_container = $(shell [ "$(shell uname)" = "Linux" ] && echo 'localhost' || echo 'docker.for.mac.localhost')
postgresql_port = $(shell cat postgresql_port 2>/dev/null || echo '5432')
postgresql_geo_port = $(shell cat postgresql_geo_port 2>/dev/null || echo '5432')
object_store_enabled = $(shell cat object_store_enabled 2>/dev/null || echo 'false')
object_store_port = $(shell cat object_store_port 2>/dev/null || echo '9000')
gitlab_pages_port = $(shell cat gitlab_pages_port 2>/dev/null || echo '3010')
rails_bundle_install_cmd := bundle install --jobs 4 --without production $(if $(shell mysql_config --libs 2>/dev/null),--with,--without) mysql
elasticsearch_version = 6.5.1
elasticsearch_tar_gz_sha1 = 5903e1913a7c96aad96a8227517c40490825f672
ruby_version = UNKNOWN
workhorse_version = $(shell bin/resolve-dependency-commitish "${gitlab_development_root}/gitlab/GITLAB_WORKHORSE_VERSION")
gitlab_shell_version = $(shell bin/resolve-dependency-commitish "${gitlab_development_root}/gitlab/GITLAB_SHELL_VERSION")
gitaly_version = $(shell bin/resolve-dependency-commitish "${gitlab_development_root}/gitlab/GITALY_SERVER_VERSION")
pages_version = $(shell bin/resolve-dependency-commitish "${gitlab_development_root}/gitlab/GITLAB_PAGES_VERSION")
tracer_build_tags = tracer_static tracer_static_jaeger
jaeger_server_enabled ?= true
jaeger_version = 1.10.1

all: gitlab-setup gitlab-shell-setup gitlab-workhorse-setup gitlab-pages-setup support-setup gitaly-setup prom-setup object-storage-setup

# Set up the GitLab Rails app

check-ruby-version:
	@if [ "${gitlab_repo_ruby_version}" != "${ruby_version}" ]; then \
		echo "WARNING: You're using Ruby version ${ruby_version}."; \
		echo "WARNING: However we recommend using Ruby version ${gitlab_repo_ruby_version} for this repository."; \
		test "${IGNORE_INSTALL_WARNINGS}" = "true" || \
		(echo "WARNING: Press <ENTER> to continue installation or <CTRL-C> to abort" && read v;) \
	fi

check-go-version:
	bin/$@

gitlab-setup: check-ruby-version gitlab/.git gitlab-config bundler .gitlab-bundle yarn .gitlab-yarn .gettext

gitlab/.git:
	git clone ${gitlab_repo} gitlab

gitlab-config: gitlab/config/gitlab.yml gitlab/config/database.yml gitlab/config/unicorn.rb gitlab/config/resque.yml gitlab/public/uploads gitlab/config/puma.rb

gitlab/config/gitlab.yml: gitlab/config/gitlab.yml.example
	bin/safe-sed "$@" \
		-e "s|/home/git|${gitlab_development_root}|g"\
		-e "s|/usr/bin/git|${git_bin}|"\
		"$<"
	hostname=${hostname} port=${port} relative_url_root=${relative_url_root}\
		https=${https}\
		webpack_port=${webpack_port}\
		registry_host=${registry_host} registry_external_port=${registry_external_port}\
		registry_enabled=${registry_enabled} registry_port=${registry_port}\
		object_store_enabled=${object_store_enabled} object_store_port=${object_store_port}\
		gitlab_pages_port=${gitlab_pages_port}\
		support/edit-gitlab.yml gitlab/config/gitlab.yml

gitlab/config/database.yml: database.yml.example
	bin/safe-sed "$@" \
		-e "s|/home/git|${gitlab_development_root}|g" \
		-e "s|5432|${postgresql_port}|" \
		"$<"

# Versions older than GitLab 11.5 won't have this file
gitlab/config/puma.example.development.rb:
	touch $@

gitlab/config/puma.rb: gitlab/config/puma.example.development.rb
	bin/safe-sed "$@" \
		-e "s|/home/git|${gitlab_development_root}|g" \
		"$<"

gitlab/config/unicorn.rb: gitlab/config/unicorn.rb.example.development
	bin/safe-sed "$@" \
		-e "s|/home/git|${gitlab_development_root}|g" \
		"$<"

gitlab/config/resque.yml: redis/resque.yml.example
	bin/safe-sed "$@" \
		-e "s|/home/git|${gitlab_development_root}|g" \
		"$<"

gitlab/public/uploads:
	mkdir $@

.gitlab-bundle:
	cd ${gitlab_development_root}/gitlab && $(rails_bundle_install_cmd)
	touch $@

.gitlab-yarn:
	cd ${gitlab_development_root}/gitlab && yarn install --pure-lockfile
	touch $@

.gettext:
	cd ${gitlab_development_root}/gitlab && bundle exec rake gettext:compile > ${gitlab_development_root}/gettext.log 2>&1
	git -C ${gitlab_development_root}/gitlab checkout locale/*/gitlab.po
	touch $@

.PHONY: bundler
bundler:
	command -v $@ > /dev/null || gem install $@ -v 1.17.3

.PHONY: yarn
yarn:
	@command -v $@ > /dev/null || {\
		echo "Error: Yarn executable was not detected in the system.";\
		echo "Download Yarn at https://yarnpkg.com/en/docs/install";\
		exit 1;\
	}

# Set up gitlab-shell

gitlab-shell-setup: symlink-gitlab-shell ${gitlab_shell_clone_dir}/.git gitlab-shell/config.yml bundler .gitlab-shell-bundle gitlab-shell/.gitlab_shell_secret
	if [ -x gitlab-shell/bin/compile ] ; then gitlab-shell/bin/compile; fi

symlink-gitlab-shell:
	support/symlink gitlab-shell ${gitlab_shell_clone_dir}

${gitlab_shell_clone_dir}/.git:
	git clone ${gitlab_shell_repo} ${gitlab_shell_clone_dir}

gitlab-shell/config.yml: gitlab-shell/config.yml.example
	bin/safe-sed "$@" \
		-e "s|/home/git|${gitlab_development_root}|g" \
		-e "s|^gitlab_url:.*|gitlab_url: http+unix://$(subst /,%2F,${gitlab_development_root}/gitlab.socket)|" \
		-e "s|/usr/bin/redis-cli|$(shell which redis-cli)|" \
		-e "s|^  socket: .*|  socket: ${gitlab_development_root}/redis/redis.socket|" \
		"$<"

.gitlab-shell-bundle:
	cd ${gitlab_development_root}/gitlab-shell && $(rails_bundle_install_cmd)
	touch $@

gitlab-shell/.gitlab_shell_secret:
	ln -s ${gitlab_development_root}/gitlab/.gitlab_shell_secret $@

# Set up gitaly

gitaly-setup: gitaly/bin/gitaly gitaly/config.toml ${gitaly_proto_clone_dir}/.git

${gitaly_clone_dir}/.git:
	git clone --quiet ${gitaly_repo} ${gitaly_clone_dir}

${gitaly_proto_clone_dir}/.git:
	git clone --quiet ${gitaly_proto_repo} ${gitaly_proto_clone_dir}

gitaly/config.toml: $(gitaly_clone_dir)/config.toml.example
	bin/safe-sed "$@" \
		-e "s|/home/git|${gitlab_development_root}|g" \
		-e "s|^socket_path.*|socket_path = \"${gitlab_development_root}/gitaly.socket\"|" \
		-e "s|^bin_dir.*|bin_dir = \"${gitlab_development_root}/gitaly/bin\"|" \
		-e "s|# prometheus_listen_addr|prometheus_listen_addr|" \
		-e "s|# \[logging\]|\[logging\]|" \
		-e "s|# level = \"warn\"|level = \"warn\"|" \
		"$<"

prom-setup:
	if [ "$(uname -s)" = "Linux" ]; then \
		sed -i -e 's/docker\.for\.mac\.localhost/localhost/g' ${gitlab_development_root}/prometheus/prometheus.yml; \
	fi

# Set up gitlab-docs

gitlab-docs-setup: gitlab-docs/.git gitlab-docs-bundle gitlab-docs/nanoc.yaml symlink-gitlab-docs

gitlab-docs/.git:
	git clone ${gitlab_docs_repo} gitlab-docs

gitlab-docs/.git/pull:
	cd gitlab-docs && \
		git stash && \
		git checkout master &&\
		git pull --ff-only


# We need to force delete since there's already a nanoc.yaml file
# in the docs folder which we need to overwrite.
gitlab-docs/rm-nanoc.yaml:
	rm -f gitlab-docs/nanoc.yaml

gitlab-docs/nanoc.yaml: gitlab-docs/rm-nanoc.yaml
	cp nanoc.yaml.example $@

gitlab-docs-bundle:
	cd ${gitlab_development_root}/gitlab-docs && bundle install --jobs 4

symlink-gitlab-docs:
	support/symlink ${gitlab_development_root}/gitlab-docs/content/docs ${gitlab_development_root}/gitlab/doc

gitlab-docs-update: gitlab-docs/.git/pull gitlab-docs-bundle gitlab-docs/nanoc.yaml

# Update GDK itself

self-update: unlock-dependency-installers
	@echo ""
	@echo "--------------------------"
	@echo "Running self-update on GDK"
	@echo "--------------------------"
	@echo ""
	cd ${gitlab_development_root} && \
		git stash && \
		git checkout master && \
		git fetch && \
		support/self-update-git-worktree

# Update gitlab, gitlab-shell, gitlab-workhorse, gitlab-pages and gitaly

update: ensure-postgres-running unlock-dependency-installers gitlab-shell-update gitlab-workhorse-update gitlab-pages-update gitaly-update gitlab-update

ensure-postgres-running:
	@test -f ${postgres_data_dir}/postmaster.pid || \
	test "${IGNORE_INSTALL_WARNINGS}" = "true" || \
	(echo "WARNING: Postgres is not running.  Run 'gdk run db' or 'gdk run' in another shell." && echo "WARNING: Hit <ENTER> to ignore or <CTRL-C> to quit." && read v;)

gitlab-update: ensure-postgres-running gitlab/.git/pull gitlab-setup
	cd ${gitlab_development_root}/gitlab && \
		bundle exec rake db:migrate db:test:prepare

gitlab-shell-update: gitlab-shell/.git/pull gitlab-shell-setup

gitlab/.git/pull:
	cd ${gitlab_development_root}/gitlab && \
		git checkout -- Gemfile.lock db/schema.rb && \
		git stash && \
		git checkout master && \
		git pull --ff-only

gitlab-shell/.git/pull:
	cd ${gitlab_development_root}/gitlab-shell && \
		git stash && \
		git fetch --all --tags --prune && \
		git checkout "${gitlab_shell_version}"

gitaly-update: gitaly/.git/pull gitaly-clean gitaly/bin/gitaly

.PHONY: gitaly/.git/pull
gitaly/.git/pull: ${gitaly_clone_dir}/.git ${gitaly_proto_clone_dir}/.git
	cd ${gitaly_clone_dir} && \
		git stash && \
		git fetch --all --tags --prune && \
		git checkout "${gitaly_version}"
	cd ${gitaly_proto_clone_dir} && \
		git stash && \
		git checkout master && \
		git pull --ff-only

gitaly-clean:
	rm -rf ${gitaly_assembly_dir}
	rm -rf gitlab/tmp/tests/gitaly

.PHONY: gitaly/bin/gitaly
gitaly/bin/gitaly: check-go-version ${gitaly_clone_dir}/.git
	make -C ${gitaly_clone_dir} assemble ASSEMBLY_ROOT=${gitaly_assembly_dir} BUNDLE_FLAGS=--no-deployment BUILD_TAGS="${tracer_build_tags}"
	mkdir -p ${gitlab_development_root}/gitaly/bin
	ln -sf ${gitaly_assembly_dir}/bin/* ${gitlab_development_root}/gitaly/bin
	rm -rf ${gitlab_development_root}/gitaly/ruby
	ln -sf ${gitaly_assembly_dir}/ruby ${gitlab_development_root}/gitaly/ruby

# Set up supporting services

support-setup: .ruby-version foreman Procfile redis gitaly-setup jaeger-setup postgresql openssh-setup nginx-setup registry-setup elasticsearch-setup
	@echo ""
	@echo "*********************************************"
	@echo "************** Setup finished! **************"
	@echo "*********************************************"
	cat HELP
	@echo "*********************************************"

Procfile: Procfile.example
	bin/safe-sed "$@" \
		-e "s|/home/git|${gitlab_development_root}|g"\
		-e "s|/usr/sbin/sshd|${sshd_bin}|"\
		-e "s|postgres |${postgres_bin_dir}/postgres |"\
		-e "s|DEV_SERVER_PORT=3808 |DEV_SERVER_PORT=${webpack_port} |"\
		-e "s|-listen-http \":3010\" |-listen-http \":${gitlab_pages_port}\" -artifacts-server http://${hostname}:${port}/api/v4 |"\
		-e "s|jaeger-VERSION|jaeger-${jaeger_version}|" \
		-e "$(if $(filter false,$(jaeger_server_enabled)),/^jaeger:/s/^/#/,/^#\s*jaeger:/s/^#\s*//)" \
		"$<"
	if [ -f .vagrant_enabled ]; then \
		echo "0.0.0.0" > host; \
		echo "3000" > port; \
	fi

redis: redis/redis.conf

redis/redis.conf: redis/redis.conf.example
	bin/safe-sed "$@" \
		-e "s|/home/git|${gitlab_development_root}|g" \
		"$<"

postgresql: postgresql/data

postgresql/data:
	${postgres_bin_dir}/initdb --locale=C -E utf-8 ${postgres_data_dir}
	support/bootstrap-rails

postgresql/port:
	./support/postgres-port ${postgres_dir} ${postgresql_port}

postgresql-sensible-defaults:
	./support/postgresql-sensible-defaults ${postgres_dir}

postgresql-replication-primary: postgresql-replication/access postgresql-replication/role postgresql-replication/config

postgresql-replication-secondary: postgresql-replication/data postgresql-replication/access postgresql-replication/backup postgresql-replication/config

postgresql-replication-primary-create-slot: postgresql-replication/slot

postgresql-replication/data:
	${postgres_bin_dir}/initdb --locale=C -E utf-8 ${postgres_data_dir}

postgresql-replication/access:
	cat support/pg_hba.conf.add >> ${postgres_data_dir}/pg_hba.conf

postgresql-replication/role:
	${postgres_bin_dir}/psql -h ${postgres_dir} -p ${postgresql_port} -d postgres -c "CREATE ROLE ${postgres_replication_user} WITH REPLICATION LOGIN;"

postgresql-replication/backup:
	$(eval postgres_primary_dir := $(realpath postgresql-primary))
	$(eval postgres_primary_port := $(shell cat ${postgres_primary_dir}/../postgresql_port 2>/dev/null || echo '5432'))

	psql -h ${postgres_primary_dir} -p ${postgres_primary_port} -d postgres -c "select pg_start_backup('base backup for streaming rep')"
	rsync -cva --inplace --exclude="*pg_xlog*" --exclude="*.pid" ${postgres_primary_dir}/data postgresql
	psql -h ${postgres_primary_dir} -p ${postgres_primary_port} -d postgres -c "select pg_stop_backup(), current_timestamp"
	./support/recovery.conf ${postgres_primary_dir} ${postgres_primary_port} > ${postgres_data_dir}/recovery.conf
	$(MAKE) postgresql/port

postgresql-replication/slot:
	${postgres_bin_dir}/psql -h ${postgres_dir} -p ${postgresql_port} -d postgres -c "SELECT * FROM pg_create_physical_replication_slot('gitlab_gdk_replication_slot');"

postgresql-replication/list-slots:
	${postgres_bin_dir}/psql -h ${postgres_dir} -p ${postgresql_port} -d postgres -c "SELECT * FROM pg_replication_slots;"

postgresql-replication/drop-slot:
	${postgres_bin_dir}/psql -h ${postgres_dir} -p ${postgresql_port} -d postgres -c "SELECT * FROM pg_drop_replication_slot('gitlab_gdk_replication_slot');"

postgresql-replication/config:
	./support/postgres-replication ${postgres_dir}

# Setup GitLab Geo databases

.PHONY: geo-setup geo-cursor
geo-setup: Procfile geo-cursor gitlab/config/database_geo.yml postgresql/geo

geo-cursor:
	grep '^geo-cursor:' Procfile || (printf ',s/^#geo-cursor/geo-cursor/\nwq\n' | ed -s Procfile)

gitlab/config/database_geo.yml: database_geo.yml.example
	bin/safe-sed "$@" \
		-e "s|/home/git|${gitlab_development_root}|g" \
		"$<"

postgresql/geo:
	${postgres_bin_dir}/initdb --locale=C -E utf-8 postgresql-geo/data
	grep '^postgresql-geo:' Procfile || (printf ',s/^#postgresql-geo/postgresql-geo/\nwq\n' | ed -s Procfile)
	support/bootstrap-geo

postgresql/geo-fdw: postgresql/geo-fdw/development/create postgresql/geo-fdw/test/create

# Function to read values from database.yml, parameters:
#   - file: e.g. database, database_geo
#   - environment: e.g. development, test
#   - value: e.g. host, port
from_db_config = $(shell grep -A6 "$(2):" ${gitlab_development_root}/gitlab/config/$(1).yml | grep -m1 "$(3):" | cut -d ':' -f 2 | tr -d ' ')

postgresql/geo-fdw/%: dbname = $(call from_db_config,database_geo,$*,database)
postgresql/geo-fdw/%: fdw_dbname = $(call from_db_config,database,$*,database)
postgresql/geo-fdw/%: fdw_host = $(call from_db_config,database,$*,host)
postgresql/geo-fdw/%: fdw_port = $(call from_db_config,database,$*,port)
postgresql/geo-fdw/test/%: rake_namespace = test:

postgresql/geo-fdw/%/create:
	${postgres_bin_dir}/psql -h ${postgres_geo_dir} -p ${postgresql_geo_port} -d ${dbname} -c "CREATE EXTENSION IF NOT EXISTS postgres_fdw;"
	${postgres_bin_dir}/psql -h ${postgres_geo_dir} -p ${postgresql_geo_port} -d ${dbname} -c "CREATE SERVER gitlab_secondary FOREIGN DATA WRAPPER postgres_fdw OPTIONS (host '$(fdw_host)', dbname '${fdw_dbname}', port '$(fdw_port)' );"
	${postgres_bin_dir}/psql -h ${postgres_geo_dir} -p ${postgresql_geo_port} -d ${dbname} -c "CREATE USER MAPPING FOR current_user SERVER gitlab_secondary OPTIONS (user '$(USER)');"
	${postgres_bin_dir}/psql -h ${postgres_geo_dir} -p ${postgresql_geo_port} -d ${dbname} -c "CREATE SCHEMA IF NOT EXISTS gitlab_secondary;"
	${postgres_bin_dir}/psql -h ${postgres_geo_dir} -p ${postgresql_geo_port} -d ${dbname} -c "GRANT USAGE ON FOREIGN SERVER gitlab_secondary TO current_user;"
	cd ${gitlab_development_root}/gitlab && bundle exec rake geo:db:${rake_namespace}refresh_foreign_tables

postgresql/geo-fdw/%/drop:
	${postgres_bin_dir}/psql -h ${postgres_geo_dir} -p ${postgresql_geo_port} -d ${dbname} -c "DROP SERVER gitlab_secondary CASCADE;"
	${postgres_bin_dir}/psql -h ${postgres_geo_dir} -p ${postgresql_geo_port} -d ${dbname} -c "DROP SCHEMA gitlab_secondary;"

postgresql/geo-fdw/%/rebuild:
	$(MAKE) postgresql/geo-fdw/$*/drop || true
	$(MAKE) postgresql/geo-fdw/$*/create

.PHONY: foreman
foreman:
	command -v $@ > /dev/null || gem install $@

.ruby-version:
	ln -s ${gitlab_development_root}/gitlab/.ruby-version ${gitlab_development_root}/$@

localhost.crt: localhost.key

localhost.key:
	openssl req -new -subj "/CN=localhost/" -x509 -days 365 -newkey rsa:2048 -nodes -keyout "localhost.key" -out "localhost.crt"
	chmod 600 $@

gitlab-workhorse-setup: gitlab-workhorse/bin/gitlab-workhorse gitlab-workhorse/config.toml

gitlab-workhorse/config.toml: gitlab-workhorse/config.toml.example
	bin/safe-sed "$@" \
		-e "s|/home/git|${gitlab_development_root}|g" \
		"$<"

gitlab-workhorse-update: ${gitlab_workhorse_clone_dir}/.git gitlab-workhorse/.git/pull gitlab-workhorse-clean-bin gitlab-workhorse/bin/gitlab-workhorse

gitlab-workhorse-clean-bin:
	rm -rf gitlab-workhorse/bin

.PHONY: gitlab-workhorse/bin/gitlab-workhorse
gitlab-workhorse/bin/gitlab-workhorse: check-go-version ${gitlab_workhorse_clone_dir}/.git
	GOPATH=${gitlab_development_root}/gitlab-workhorse go install -tags "${tracer_build_tags}" gitlab.com/gitlab-org/gitlab-workhorse/...

${gitlab_workhorse_clone_dir}/.git:
	git clone ${gitlab_workhorse_repo} ${gitlab_workhorse_clone_dir}

gitlab-workhorse/.git/pull:
	cd ${gitlab_workhorse_clone_dir} && \
		git stash && \
		git fetch --all --tags --prune && \
		git checkout "${workhorse_version}"

gitlab-pages-setup: gitlab-pages/bin/gitlab-pages

gitlab-pages-update: ${gitlab_pages_clone_dir}/.git gitlab-pages/.git/pull gitlab-pages-clean-bin gitlab-pages/bin/gitlab-pages

gitlab-pages-clean-bin:
	rm -rf gitlab-pages/bin

.PHONY: gitlab-pages/bin/gitlab-pages
gitlab-pages/bin/gitlab-pages: check-go-version ${gitlab_pages_clone_dir}/.git
	GOPATH=${gitlab_development_root}/gitlab-pages go install gitlab.com/gitlab-org/gitlab-pages

${gitlab_pages_clone_dir}/.git:
	git clone ${gitlab_pages_repo} ${gitlab_pages_clone_dir}

gitlab-pages/.git/pull:
	cd ${gitlab_pages_clone_dir} && \
		git stash &&\
		git fetch --all --tags --prune && \
		git checkout "${pages_version}"

influxdb-setup: influxdb/influxdb.conf influxdb/bin/influxd influxdb/meta/meta.db

influxdb/bin/influxd:
	cd influxdb && ${MAKE}

influxdb/meta/meta.db: Procfile
	grep '^influxdb:' Procfile || (printf ',s/^#influxdb/influxdb/\nwq\n' | ed -s Procfile)
	support/bootstrap-influxdb 8086

influxdb/influxdb.conf: influxdb/influxdb.conf.example
	bin/safe-sed "$@" \
		-e "s|/home/git|${gitlab_development_root}|g" \
		"$<"

grafana-setup: grafana/grafana.ini grafana/bin/grafana-server grafana/gdk-pg-created grafana/gdk-data-source-created

grafana/bin/grafana-server:
	cd grafana && ${MAKE}

grafana/grafana.ini: grafana/grafana.ini.example
	bin/safe-sed "$@" \
		-e "s|/home/git|${gitlab_development_root}|g" \
		-e "s/GDK_USERNAME/${username}/g" \
		"$<"

grafana/gdk-pg-created:
	PATH=${postgres_bin_dir}:${PATH} support/create-grafana-db
	touch $@

grafana/gdk-data-source-created:
	grep '^grafana:' Procfile || (printf ',s/^#grafana/grafana/\nwq\n' | ed -s Procfile)
	support/bootstrap-grafana
	touch $@

performance-metrics-setup: Procfile influxdb-setup grafana-setup

openssh-setup: openssh/sshd_config openssh/ssh_host_rsa_key

openssh/sshd_config: openssh/sshd_config.example
	bin/safe-sed "$@" \
		-e "s|/home/git|${gitlab_development_root}|g" \
		-e "s/GDK_USERNAME/${username}/g" \
		"$<"

openssh/ssh_host_rsa_key:
	ssh-keygen -f $@ -N '' -t rsa

nginx-setup: nginx/conf/nginx.conf nginx/logs nginx/tmp

nginx/conf/nginx.conf: nginx/conf/nginx.conf.example
	bin/safe-sed "$@" \
		-e "s|/home/git|${gitlab_development_root}|g" \
		"$<"

nginx/logs:
	mkdir -p $@

nginx/tmp:
	mkdir -p $@

registry-setup: registry/storage registry/config.yml localhost.crt

registry/storage:
	mkdir -p $@

registry/config.yml:
	cp registry/config.yml.example $@
	gitlab_host=${gitlab_from_container} gitlab_port=${port} registry_port=${registry_port} support/edit-registry-config.yml $@

elasticsearch-setup: elasticsearch/bin/elasticsearch

elasticsearch/bin/elasticsearch: elasticsearch-${elasticsearch_version}.tar.gz
	rm -rf elasticsearch
	tar zxf elasticsearch-${elasticsearch_version}.tar.gz
	mv elasticsearch-${elasticsearch_version} elasticsearch
	touch $@

elasticsearch-${elasticsearch_version}.tar.gz:
	curl -L -o $@.tmp https://artifacts.elastic.co/downloads/elasticsearch/$@
	echo "${elasticsearch_tar_gz_sha1}  $@.tmp" | shasum -a1 -c -
	mv $@.tmp $@

object-storage-setup: minio/data/lfs-objects minio/data/artifacts minio/data/uploads minio/data/packages

minio/data/%:
	mkdir -p $@

pry:
	grep '^#rails-web:' Procfile || (printf ',s/^rails-web/#rails-web/\nwq\n' | ed -s Procfile)
	@echo ""
	@echo "Commented out 'rails-web' line in the Procfile.  Use 'make pry-off' to reverse."
	@echo "You can now use Pry for debugging by using 'gdk run' in one terminal, and 'gdk run thin' in another."

pry-off:
	grep '^rails-web:' Procfile || (printf ',s/^#rails-web/rails-web/\nwq\n' | ed -s Procfile)
	@echo ""
	@echo "Re-enabled 'rails-web' in the Procfile.  Debugging with Pry will no longer work."

ifeq ($(jaeger_server_enabled),true)
.PHONY: jaeger-setup
jaeger-setup: jaeger/jaeger-${jaeger_version}/jaeger-all-in-one
else
.PHONY: jaeger-setup
jaeger-setup:
	@echo Skipping jaeger-setup as Jaeger has been disabled.
endif

jaeger-artifacts/jaeger-${jaeger_version}.tar.gz:
	mkdir -p $(@D)
	./bin/download-jaeger "${jaeger_version}" "$@"
	# To save disk space, delete old versions of the download,
	# but to save bandwidth keep the current version....
	find jaeger-artifacts ! -path "$@" -type f -exec rm -f {} + -print

jaeger/jaeger-${jaeger_version}/jaeger-all-in-one: jaeger-artifacts/jaeger-${jaeger_version}.tar.gz
	mkdir -p "jaeger/jaeger-${jaeger_version}"
	tar -xf "$<" -C "jaeger/jaeger-${jaeger_version}" --strip-components 1

clean-config:
	rm -rf \
	gitlab/config/gitlab.yml \
	gitlab/config/database.yml \
	gitlab/config/unicorn.rb \
	gitlab/config/puma.rb \
	gitlab/config/resque.yml \
	gitlab-shell/config.yml \
	gitlab-shell/.gitlab_shell_secret \
	redis/redis.conf \
	.ruby-version \
	Procfile \
	gitlab-workhorse/config.toml \
	gitaly/config.toml \
	nginx/conf/nginx.conf \
	registry/config.yml \
	jaeger \

unlock-dependency-installers:
	rm -f \
	.gitlab-bundle \
	.gitlab-shell-bundle \
	.gitlab-yarn \
	.gettext \
