.NOTPARALLEL:

# Generate a Makefile from Ruby and include it
include $(shell rake gdk-config.mk)

gitlab_clone_dir = gitlab
gitlab_shell_clone_dir = go-gitlab-shell/src/gitlab.com/gitlab-org/gitlab-shell
gitlab_workhorse_clone_dir = gitlab-workhorse/src/gitlab.com/gitlab-org/gitlab-workhorse
gitaly_gopath = $(abspath ./gitaly)
gitaly_clone_dir = ${gitaly_gopath}/src/gitlab.com/gitlab-org/gitaly
gitlab_pages_clone_dir = gitlab-pages/src/gitlab.com/gitlab-org/gitlab-pages
gitaly_assembly_dir = ${gitlab_development_root}/gitaly/assembly
gitlab_from_container = $(shell [ "$(shell uname)" = "Linux" ] && echo 'localhost' || echo 'docker.for.mac.localhost')
postgres_dev_db = gitlabhq_development
rails_bundle_install_cmd = bundle install --jobs 4 --without production
workhorse_version = $(shell bin/resolve-dependency-commitish "${gitlab_development_root}/gitlab/GITLAB_WORKHORSE_VERSION")
gitlab_shell_version = $(shell bin/resolve-dependency-commitish "${gitlab_development_root}/gitlab/GITLAB_SHELL_VERSION")
gitaly_version = $(shell bin/resolve-dependency-commitish "${gitlab_development_root}/gitlab/GITALY_SERVER_VERSION")
pages_version = $(shell bin/resolve-dependency-commitish "${gitlab_development_root}/gitlab/GITLAB_PAGES_VERSION")
gitlab_elasticsearch_indexer_version = $(shell bin/resolve-dependency-commitish "${gitlab_development_root}/gitlab/GITLAB_ELASTICSEARCH_INDEXER_VERSION")
tracer_build_tags = tracer_static tracer_static_jaeger

# Borrowed from https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/tree/Makefile#n87
#
ifeq ($(gdk_debug),true)
	Q =
	QQ =
else
	Q = @
	QQ = > /dev/null
endif

ifeq ($(shallow_clone),true)
git_depth_param = --depth=1
endif

all: preflight-checks gitlab-setup gitlab-shell-setup gitlab-workhorse-setup gitlab-pages-setup support-setup gitaly-setup prom-setup object-storage-setup gitlab-elasticsearch-indexer-setup

.PHONY: preflight-checks
preflight-checks: rake
	$(Q)rake $@

.PHONY: rake
rake:
	$(Q)command -v $@ ${QQ} || gem install $@

gitlab-setup: gitlab/.git .ruby-version gitlab-config .gitlab-bundle .gitlab-yarn .gettext

gitlab/.git:
	$(Q)git clone ${git_depth_param} ${gitlab_repo} ${gitlab_clone_dir} $(if $(realpath ${gitlab_repo}),--shared)

gitlab-config: gitlab/config/gitlab.yml gitlab/config/database.yml gitlab/config/unicorn.rb gitlab/config/resque.yml gitlab/public/uploads gitlab/config/puma.rb

.PHONY: gitlab/config/gitlab.yml
gitlab/config/gitlab.yml:
	$(Q)rake gitlab/config/gitlab.yml

gitlab/config/database.yml: database.yml.example
	$(Q)bin/safe-sed "$@" \
		-e "s|/home/git|${gitlab_development_root}|g" \
		-e "s|5432|${postgresql_port}|" \
		"$<"

# Versions older than GitLab 11.5 won't have this file
gitlab/config/puma.example.development.rb:
	$(Q)touch $@

gitlab/config/puma.rb: gitlab/config/puma.example.development.rb
	$(Q)bin/safe-sed "$@" \
		-e "s|/home/git|${gitlab_development_root}|g" \
		"$<"

gitlab/config/unicorn.rb: gitlab/config/unicorn.rb.example.development
	$(Q)bin/safe-sed "$@" \
		-e "s|/home/git|${gitlab_development_root}|g" \
		"$<"

gitlab/config/resque.yml: redis/resque.yml.example
	$(Q)bin/safe-sed "$@" \
		-e "s|/home/git|${gitlab_development_root}|g" \
		"$<"

gitlab/public/uploads:
	$(Q)mkdir $@

.gitlab-bundle:
	$(Q)cd ${gitlab_development_root}/gitlab && $(rails_bundle_install_cmd) ${QQ}
	$(Q)touch $@

.gitlab-yarn:
	$(Q)cd ${gitlab_development_root}/gitlab && yarn install --pure-lockfile ${QQ}
	$(Q)touch $@

.gettext:
	$(Q)cd ${gitlab_development_root}/gitlab && bundle exec rake gettext:compile > ${gitlab_development_root}/gettext.log 2>&1
	$(Q)git -C ${gitlab_development_root}/gitlab checkout locale/*/gitlab.po
	$(Q)touch $@

gitlab-shell-setup: symlink-gitlab-shell ${gitlab_shell_clone_dir}/.git gitlab-shell/config.yml .gitlab-shell-bundle gitlab-shell/.gitlab_shell_secret
	$(Q)make -C gitlab-shell build ${QQ}

symlink-gitlab-shell:
	$(Q)support/symlink gitlab-shell ${gitlab_shell_clone_dir}

${gitlab_shell_clone_dir}/.git:
	$(Q)git clone --quiet --branch "${gitlab_shell_version}" ${git_depth_param} ${gitlab_shell_repo} ${gitlab_shell_clone_dir}

gitlab-shell/config.yml: gitlab-shell/config.yml.example
	$(Q)bin/safe-sed "$@" \
		-e "s|/home/git|${gitlab_development_root}|g" \
		-e "s|^gitlab_url:.*|gitlab_url: http+unix://$(subst /,%2F,${gitlab_development_root}/gitlab.socket)|" \
		-e "s|/usr/bin/redis-cli|$(shell which redis-cli)|" \
		-e "s|^  socket: .*|  socket: ${gitlab_development_root}/redis/redis.socket|" \
		-e "s|^# migration|migration|" \
		"$<"

.gitlab-shell-bundle:
	$(Q)cd ${gitlab_development_root}/gitlab-shell && $(rails_bundle_install_cmd) ${QQ}
	$(Q)touch $@

gitlab-shell/.gitlab_shell_secret:
	$(Q)ln -s ${gitlab_development_root}/gitlab/.gitlab_shell_secret $@

gitaly-setup: gitaly/bin/gitaly gitaly/gitaly.config.toml gitaly/praefect.config.toml

${gitaly_clone_dir}/.git:
	git clone --quiet --branch "${gitaly_version}" ${git_depth_param} ${gitaly_repo} ${gitaly_clone_dir}

.PHONY: gitaly/gitaly.config.toml
gitaly/gitaly.config.toml:
	$(Q)rake gitaly/gitaly.config.toml

.PHONY: gitaly/praefect.config.toml
gitaly/praefect.config.toml:
	$(Q)rake gitaly/praefect.config.toml

prom-setup:
	$(Q)[ "$(uname -s)" = "Linux" ] && sed -i -e 's/docker\.for\.mac\.localhost/localhost/g' ${gitlab_development_root}/prometheus/prometheus.yml || true

gitlab-docs-setup: gitlab-docs/.git gitlab-docs-bundle gitlab-docs/nanoc.yaml symlink-gitlab-docs

gitlab-docs/.git:
	$(Q)git clone ${git_depth_param} ${gitlab_docs_repo} gitlab-docs

gitlab-docs/.git/pull:
	@echo
	@echo "-------------------------------------------------------"
	@echo "Updating gitlab-docs.."
	@echo "-------------------------------------------------------"
	$(Q)cd gitlab-docs && \
		git stash ${QQ} && \
		git checkout master ${QQ} &&\
		git pull --ff-only ${QQ}

# We need to force delete since there's already a nanoc.yaml file
# in the docs folder which we need to overwrite.
gitlab-docs/rm-nanoc.yaml:
	$(Q)rm -f gitlab-docs/nanoc.yaml

gitlab-docs/nanoc.yaml: gitlab-docs/rm-nanoc.yaml
	$(Q)cp nanoc.yaml.example $@

gitlab-docs-bundle:
	$(Q)cd ${gitlab_development_root}/gitlab-docs && bundle install --jobs 4

symlink-gitlab-docs:
	$(Q)support/symlink ${gitlab_development_root}/gitlab-docs/content/ee ${gitlab_development_root}/gitlab/doc

gitlab-docs-update: gitlab-docs/.git/pull gitlab-docs-bundle gitlab-docs/nanoc.yaml

self-update: unlock-dependency-installers
	@echo
	@echo "-------------------------------------------------------"
	@echo "Running self-update on GDK"
	@echo "-------------------------------------------------------"
	$(Q)cd ${gitlab_development_root} && \
		git stash ${QQ} && \
		git checkout master ${QQ} && \
		git fetch ${QQ} && \
		support/self-update-git-worktree ${QQ}

# Update gitlab, gitlab-shell, gitlab-workhorse, gitlab-pages and gitaly
# Pull gitlab directory first since dependencies are linked from there.
update: stop-foreman ensure-databases-running unlock-dependency-installers gitlab/.git/pull gitlab-shell-update gitlab-workhorse-update gitlab-pages-update gitaly-update gitlab-update gitlab-elasticsearch-indexer-update

stop-foreman:
	$(Q)pkill foreman || true

.PHONY: ensure-databases-running
ensure-databases-running: Procfile postgresql/data
	$(Q)gdk start rails-migration-dependencies

gitlab-update: ensure-databases-running postgresql gitlab/.git/pull gitlab-setup
	$(Q)cd ${gitlab_development_root}/gitlab && \
		bundle exec rake db:migrate db:test:prepare

gitlab-shell-update: gitlab-shell/.git/pull gitlab-shell-setup

gitlab/.git/pull:
	@echo
	@echo "-------------------------------------------------------"
	@echo "Updating gitlab to current master.."
	@echo "-------------------------------------------------------"
	$(Q)cd ${gitlab_development_root}/gitlab && \
		git checkout -- Gemfile.lock db/schema.rb ${QQ} && \
		git stash ${QQ} && \
		git checkout master ${QQ} && \
		git pull --ff-only ${QQ}

gitlab-shell/.git/pull:
	@echo
	@echo "-------------------------------------------------------"
	@echo "Updating gitlab-shell to ${gitlab_shell_version}.."
	@echo "-------------------------------------------------------"
	$(Q)support/component-git-update gitlab_shell "${gitlab_development_root}/gitlab-shell" "${gitlab_shell_version}"

gitaly-update: gitaly/.git/pull gitaly-clean gitaly/bin/gitaly

.PHONY: gitaly/.git/pull
gitaly/.git/pull: ${gitaly_clone_dir}/.git
	@echo
	@echo "-------------------------------------------------------"
	@echo "Updating gitaly to ${gitaly_version}.."
	@echo "-------------------------------------------------------"
	$(Q)support/component-git-update gitaly "${gitaly_clone_dir}" "${gitaly_version}" ${QQ}

gitaly-clean:
	$(Q)rm -rf ${gitaly_assembly_dir}
	$(Q)rm -rf gitlab/tmp/tests/gitaly

.PHONY: gitaly/bin/gitaly
gitaly/bin/gitaly: ${gitaly_clone_dir}/.git
	$(Q)$(MAKE) -C ${gitaly_clone_dir} assemble ASSEMBLY_ROOT=${gitaly_assembly_dir} BUNDLE_FLAGS=--no-deployment BUILD_TAGS="${tracer_build_tags}" ${QQ}
	$(Q)mkdir -p ${gitlab_development_root}/gitaly/bin
	$(Q)ln -sf ${gitaly_assembly_dir}/bin/* ${gitlab_development_root}/gitaly/bin
	$(Q)rm -rf ${gitlab_development_root}/gitaly/ruby
	$(Q)ln -sf ${gitaly_assembly_dir}/ruby ${gitlab_development_root}/gitaly/ruby

support-setup: Procfile redis gitaly-setup jaeger-setup postgresql openssh-setup nginx-setup registry-setup elasticsearch-setup
	@echo
	@echo "-------------------------------------------------------"
	@echo "Setup finished!"
	@echo "-------------------------------------------------------"
	@echo
	$(Q)cat HELP

ifeq ($(auto_devops_enabled),true)
	@echo
	@echo "-------------------------------------------------------"
	@echo "Tunnel URLs"
	@echo
	@echo "GitLab: https://${hostname}"
	@echo "Registry: https://${registry_host}"
	@echo "-------------------------------------------------------"
endif

gdk.yml:
	$(Q)touch $@

.PHONY: Procfile
Procfile:
	$(Q)rake $@

redis: redis/redis.conf

redis/redis.conf: redis/redis.conf.example
	$(Q)bin/safe-sed "$@" \
		-e "s|/home/git|${gitlab_development_root}|g" \
		"$<"

postgresql: postgresql/data postgresql/port postgresql-seed-rails postgresql-seed-praefect

postgresql/data:
	$(Q)${postgres_bin_dir}/initdb --locale=C -E utf-8 ${postgres_data_dir}

.PHONY: postgresql-seed-rails
postgresql-seed-rails: ensure-databases-running
	$(Q)support/bootstrap-rails

.PHONY: postgresql-seed-praefect
postgresql-seed-praefect: ensure-databases-running
	$(Q)support/bootstrap-praefect

postgresql/port:
	$(Q)support/postgres-port ${postgres_dir} ${postgresql_port}

postgresql-sensible-defaults:
	$(Q)support/postgresql-sensible-defaults ${postgres_dir}

postgresql-replication-primary: postgresql-replication/access postgresql-replication/role postgresql-replication/config

postgresql-replication-secondary: postgresql-replication/data postgresql-replication/access postgresql-replication/backup postgresql-replication/config

postgresql-replication-primary-create-slot: postgresql-replication/slot

postgresql-replication/data:
	${postgres_bin_dir}/initdb --locale=C -E utf-8 ${postgres_data_dir}

postgresql-replication/access:
	$(Q)cat support/pg_hba.conf.add >> ${postgres_data_dir}/pg_hba.conf

postgresql-replication/role:
	$(Q)${postgres_bin_dir}/psql -h ${postgres_dir} -p ${postgresql_port} -d postgres -c "CREATE ROLE ${postgres_replication_user} WITH REPLICATION LOGIN;"

postgresql-replication/backup:
	$(Q)$(eval postgres_primary_dir := $(realpath postgresql-primary))
	$(Q)$(eval postgres_primary_port := $(shell cat ${postgres_primary_dir}/../postgresql_port 2>/dev/null || echo '5432'))

	$(Q)psql -h ${postgres_primary_dir} -p ${postgres_primary_port} -d postgres -c "select pg_start_backup('base backup for streaming rep')"
	$(Q)rsync -cva --inplace --exclude="*pg_xlog*" --exclude="*.pid" ${postgres_primary_dir}/data postgresql
	$(Q)psql -h ${postgres_primary_dir} -p ${postgres_primary_port} -d postgres -c "select pg_stop_backup(), current_timestamp"
	$(Q)./support/recovery.conf ${postgres_primary_dir} ${postgres_primary_port} > ${postgres_data_dir}/recovery.conf
	$(Q)$(MAKE) postgresql/port ${QQ}

postgresql-replication/slot:
	$(Q)${postgres_bin_dir}/psql -h ${postgres_dir} -p ${postgresql_port} -d postgres -c "SELECT * FROM pg_create_physical_replication_slot('gitlab_gdk_replication_slot');"

postgresql-replication/list-slots:
	$(Q)${postgres_bin_dir}/psql -h ${postgres_dir} -p ${postgresql_port} -d postgres -c "SELECT * FROM pg_replication_slots;"

postgresql-replication/drop-slot:
	$(Q)${postgres_bin_dir}/psql -h ${postgres_dir} -p ${postgresql_port} -d postgres -c "SELECT * FROM pg_drop_replication_slot('gitlab_gdk_replication_slot');"

postgresql-replication/config:
	$(Q)./support/postgres-replication ${postgres_dir}

# Setup GitLab Geo databases

.PHONY: geo-setup geo-cursor
geo-setup: Procfile geo-cursor gitlab/config/database_geo.yml postgresql/geo

geo-cursor:
	$(Q)grep '^geo-cursor:' Procfile || (printf ',s/^#geo-cursor/geo-cursor/\nwq\n' | ed -s Procfile)

gitlab/config/database_geo.yml: database_geo.yml.example
	$(Q)bin/safe-sed "$@" \
		-e "s|/home/git|${gitlab_development_root}|g" \
		"$<"

postgresql/geo:
	$(Q)${postgres_bin_dir}/initdb --locale=C -E utf-8 postgresql-geo/data
	$(Q)grep '^postgresql-geo:' Procfile || (printf ',s/^#postgresql-geo/postgresql-geo/\nwq\n' | ed -s Procfile)
	$(Q)support/bootstrap-geo

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
	$(Q)${postgres_bin_dir}/psql -h ${postgres_geo_dir} -p ${postgresql_geo_port} -d ${dbname} -c "CREATE EXTENSION IF NOT EXISTS postgres_fdw;"
	$(Q)${postgres_bin_dir}/psql -h ${postgres_geo_dir} -p ${postgresql_geo_port} -d ${dbname} -c "CREATE SERVER gitlab_secondary FOREIGN DATA WRAPPER postgres_fdw OPTIONS (host '$(fdw_host)', dbname '${fdw_dbname}', port '$(fdw_port)' );"
	$(Q)${postgres_bin_dir}/psql -h ${postgres_geo_dir} -p ${postgresql_geo_port} -d ${dbname} -c "CREATE USER MAPPING FOR current_user SERVER gitlab_secondary OPTIONS (user '$(USER)');"
	$(Q)${postgres_bin_dir}/psql -h ${postgres_geo_dir} -p ${postgresql_geo_port} -d ${dbname} -c "CREATE SCHEMA IF NOT EXISTS gitlab_secondary;"
	$(Q)${postgres_bin_dir}/psql -h ${postgres_geo_dir} -p ${postgresql_geo_port} -d ${dbname} -c "GRANT USAGE ON FOREIGN SERVER gitlab_secondary TO current_user;"
	$(Q)cd ${gitlab_development_root}/gitlab && bundle exec rake geo:db:${rake_namespace}refresh_foreign_tables

postgresql/geo-fdw/%/drop:
	$(Q)${postgres_bin_dir}/psql -h ${postgres_geo_dir} -p ${postgresql_geo_port} -d ${dbname} -c "DROP SERVER gitlab_secondary CASCADE;"
	$(Q)${postgres_bin_dir}/psql -h ${postgres_geo_dir} -p ${postgresql_geo_port} -d ${dbname} -c "DROP SCHEMA gitlab_secondary;"

postgresql/geo-fdw/%/rebuild:
	$(Q)$(MAKE) postgresql/geo-fdw/$*/drop || true ${QQ}
	$(Q)$(MAKE) postgresql/geo-fdw/$*/create ${QQ}

.PHONY: geo-primary-migrate
geo-primary-migrate: ensure-databases-running
	$(Q)cd ${gitlab_development_root}/gitlab && \
		bundle install && \
		bundle exec rake db:migrate db:test:prepare geo:db:migrate geo:db:test:prepare && \
		git checkout -- db/schema.rb ee/db/geo/schema.rb
	$(Q)$(MAKE) postgresql/geo-fdw/test/rebuild ${QQ}

.PHONY: geo-primary-update
geo-primary-update: update geo-primary-migrate
	$(Q)gdk diff-config

.PHONY: geo-secondary-migrate
geo-secondary-migrate: ensure-databases-running
	$(Q)cd ${gitlab_development_root}/gitlab && \
		${rails_bundle_install_cmd} ${QQ} && \
		bundle exec rake geo:db:migrate && \
		git checkout -- ee/db/geo/schema.rb
	$(Q)$(MAKE) postgresql/geo-fdw/development/rebuild ${QQ}

.PHONY: geo-secondary-update
geo-secondary-update:
	$(Q)-$(MAKE) update ${QQ}
	$(Q)$(MAKE) geo-secondary-migrate ${QQ}
	$(Q)gdk diff-config

.ruby-version:
	$(Q)ln -s ${gitlab_development_root}/gitlab/.ruby-version ${gitlab_development_root}/$@

localhost.crt: localhost.key

localhost.key:
	$(Q)openssl req -new -subj "/CN=localhost/" -x509 -days 365 -newkey rsa:2048 -nodes -keyout "localhost.key" -out "localhost.crt"
	$(Q)chmod 600 $@

gitlab-workhorse-setup: gitlab-workhorse/bin/gitlab-workhorse gitlab-workhorse/config.toml

gitlab-workhorse/config.toml: gitlab-workhorse/config.toml.example
	$(Q)bin/safe-sed "$@" \
		-e "s|/home/git|${gitlab_development_root}|g" \
		"$<"

gitlab-workhorse-update: ${gitlab_workhorse_clone_dir}/.git gitlab-workhorse/.git/pull gitlab-workhorse-clean-bin gitlab-workhorse/bin/gitlab-workhorse

gitlab-workhorse-clean-bin:
	$(Q)rm -rf gitlab-workhorse/bin

.PHONY: gitlab-workhorse/bin/gitlab-workhorse
gitlab-workhorse/bin/gitlab-workhorse: ${gitlab_workhorse_clone_dir}/.git
	$(Q)$(MAKE) -C ${gitlab_workhorse_clone_dir} install PREFIX=${gitlab_development_root}/gitlab-workhorse ${QQ}

${gitlab_workhorse_clone_dir}/.git:
	$(Q)git clone --quiet --branch "${workhorse_version}" ${git_depth_param} ${gitlab_workhorse_repo} ${gitlab_workhorse_clone_dir}

gitlab-workhorse/.git/pull:
	@echo
	@echo "-------------------------------------------------------"
	@echo "Updating gitlab-workhorse to ${workhorse_version}.."
	@echo "-------------------------------------------------------"
	$(Q)support/component-git-update workhorse "${gitlab_workhorse_clone_dir}" "${workhorse_version}"

gitlab-pages-setup: gitlab-pages/bin/gitlab-pages

gitlab-pages-update: ${gitlab_pages_clone_dir}/.git gitlab-pages/.git/pull gitlab-pages-clean-bin gitlab-pages/bin/gitlab-pages

gitlab-pages-clean-bin:
	$(Q)rm -rf gitlab-pages/bin

.PHONY: gitlab-pages/bin/gitlab-pages
gitlab-pages/bin/gitlab-pages: ${gitlab_pages_clone_dir}/.git
	$(Q)mkdir -p gitlab-pages/bin
	$(Q)$(MAKE) -C ${gitlab_pages_clone_dir} ${QQ}
	$(Q)install -m755 ${gitlab_pages_clone_dir}/gitlab-pages gitlab-pages/bin

${gitlab_pages_clone_dir}/.git:
	$(Q)git clone --quiet --branch "${pages_version}" ${git_depth_param} ${gitlab_pages_repo} ${gitlab_pages_clone_dir} ${QQ}

gitlab-pages/.git/pull:
	@echo
	@echo "-------------------------------------------------------"
	@echo "Updating gitlab-pages to ${pages_version}.."
	@echo "-------------------------------------------------------"
	$(Q)support/component-git-update gitlab_pages "${gitlab_pages_clone_dir}" "${pages_version}"

influxdb-setup: influxdb/influxdb.conf influxdb/bin/influxd influxdb/meta/meta.db

influxdb/bin/influxd:
	$(Q)cd influxdb && ${MAKE} ${QQ}

influxdb/meta/meta.db: Procfile
	$(Q)grep '^influxdb:' Procfile || (printf ',s/^#influxdb/influxdb/\nwq\n' | ed -s Procfile)
	$(Q)support/bootstrap-influxdb 8086

influxdb/influxdb.conf: influxdb/influxdb.conf.example
	$(Q)bin/safe-sed "$@" \
		-e "s|/home/git|${gitlab_development_root}|g" \
		"$<"

grafana-setup: grafana/grafana.ini grafana/bin/grafana-server grafana/gdk-pg-created grafana/gdk-data-source-created

grafana/bin/grafana-server:
	$(Q)cd grafana && ${MAKE} ${QQ}

grafana/grafana.ini: grafana/grafana.ini.example
	$(Q)bin/safe-sed "$@" \
		-e "s|/home/git|${gitlab_development_root}|g" \
		-e "s/GDK_USERNAME/${username}/g" \
		"$<"

grafana/gdk-pg-created:
	$(Q)support/create-grafana-db
	$(Q)touch $@

grafana/gdk-data-source-created:
	$(Q)grep '^grafana:' Procfile || (printf ',s/^#grafana/grafana/\nwq\n' | ed -s Procfile)
	$(Q)support/bootstrap-grafana
	$(Q)touch $@

performance-metrics-setup: Procfile influxdb-setup grafana-setup

openssh-setup: openssh/sshd_config openssh/ssh_host_rsa_key

openssh/ssh_host_rsa_key:
	$(Q)ssh-keygen -f $@ -N '' -t rsa

nginx-setup: nginx/conf/nginx.conf nginx/logs nginx/tmp

.PHONY: nginx/conf/nginx.conf
nginx/conf/nginx.conf:
	$(Q)rake $@

.PHONY: openssh/sshd_config
openssh/sshd_config:
	$(Q)rake $@

nginx/logs:
	$(Q)mkdir -p $@

nginx/tmp:
	$(Q)mkdir -p $@

registry-setup: registry/storage registry/config.yml localhost.crt

registry/storage:
	$(Q)mkdir -p $@

registry/config.yml:
	$(Q)cp registry/config.yml.example $@
	if ${auto_devops_enabled}; then \
		protocol='https' gitlab_host=${hostname} gitlab_port=${port} registry_port=${registry_port} \
		support/edit-registry-config.yml $@; \
	else \
		gitlab_host=${gitlab_from_container} gitlab_port=${port} registry_port=${registry_port} \
		support/edit-registry-config.yml $@; \
	fi

elasticsearch-setup: elasticsearch/bin/elasticsearch

elasticsearch/bin/elasticsearch: elasticsearch-${elasticsearch_version}.tar.gz
	$(Q)rm -rf elasticsearch
	$(Q)tar zxf elasticsearch-${elasticsearch_version}.tar.gz
	$(Q)mv elasticsearch-${elasticsearch_version} elasticsearch
	$(Q)touch $@

elasticsearch-${elasticsearch_version}.tar.gz:
	$(Q)curl -L -o $@.tmp https://artifacts.elastic.co/downloads/elasticsearch/$@
	$(Q)echo "${elasticsearch_tar_gz_sha1}  $@.tmp" | shasum -a1 -c -
	$(Q)mv $@.tmp $@

gitlab-elasticsearch-indexer-setup: gitlab-elasticsearch-indexer/bin/gitlab-elasticsearch-indexer

gitlab-elasticsearch-indexer-update: gitlab-elasticsearch-indexer/.git/pull gitlab-elasticsearch-indexer-clean-bin gitlab-elasticsearch-indexer/bin/gitlab-elasticsearch-indexer

gitlab-elasticsearch-indexer-clean-bin:
	$(Q)rm -rf gitlab-elasticsearch-indexer/bin

gitlab-elasticsearch-indexer/.git:
	$(Q)git clone --quiet --branch "${gitlab_elasticsearch_indexer_version}" ${git_depth_param} ${gitlab_elasticsearch_indexer_repo} gitlab-elasticsearch-indexer

.PHONY: gitlab-elasticsearch-indexer/bin/gitlab-elasticsearch-indexer
gitlab-elasticsearch-indexer/bin/gitlab-elasticsearch-indexer: gitlab-elasticsearch-indexer/.git
	$(Q)$(MAKE) -C gitlab-elasticsearch-indexer build ${QQ}

.PHONY: gitlab-elasticsearch-indexer/.git/pull
gitlab-elasticsearch-indexer/.git/pull: gitlab-elasticsearch-indexer/.git
	@echo
	@echo "-------------------------------------------------------"
	@echo "Updating gitlab-elasticsearch-indexer to ${gitlab_elasticsearch_indexer_version}.."
	@echo "-------------------------------------------------------"
	$(Q)support/component-git-update gitlab_elasticsearch_indexer gitlab-elasticsearch-indexer "${gitlab_elasticsearch_indexer_version}"

object-storage-setup: minio/data/lfs-objects minio/data/artifacts minio/data/uploads minio/data/packages

minio/data/%:
	$(Q)mkdir -p $@

ifeq ($(jaeger_server_enabled),true)
.PHONY: jaeger-setup
jaeger-setup: jaeger/jaeger-${jaeger_version}/jaeger-all-in-one
else
.PHONY: jaeger-setup
jaeger-setup:
	@true
endif

jaeger-artifacts/jaeger-${jaeger_version}.tar.gz:
	$(Q)mkdir -p $(@D)
	$(Q)./bin/download-jaeger "${jaeger_version}" "$@"
	# To save disk space, delete old versions of the download,
	# but to save bandwidth keep the current version....
	$(Q)find jaeger-artifacts ! -path "$@" -type f -exec rm -f {} + -print

jaeger/jaeger-${jaeger_version}/jaeger-all-in-one: jaeger-artifacts/jaeger-${jaeger_version}.tar.gz
	@echo
	@echo "-------------------------------------------------------"
	@echo "Installing jaeger ${jaeger_version}.."
	@echo "-------------------------------------------------------"

	$(Q)mkdir -p "jaeger/jaeger-${jaeger_version}"
	$(Q)tar -xf "$<" -C "jaeger/jaeger-${jaeger_version}" --strip-components 1

clean-config:
	$(Q)rm -rf \
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
	gitaly/gitaly.config.toml \
	nginx/conf/nginx.conf \
	registry/config.yml \
	jaeger

touch-examples:
	$(Q)touch \
	Procfile.erb \
	database.yml.example \
	database_geo.yml.example \
	gitlab-shell/config.yml.example \
	gitlab-workhorse/config.toml.example \
	gitlab/config/puma.example.development.rb \
	gitlab/config/unicorn.rb.example.development \
	grafana/grafana.ini.example \
	influxdb/influxdb.conf.example \
	redis/redis.conf.example \
	redis/resque.yml.example \
	registry/config.yml.example \
	support/templates/*.erb

unlock-dependency-installers:
	$(Q)rm -f \
	.gitlab-bundle \
	.gitlab-shell-bundle \
	.gitlab-yarn \
	.gettext \

.PHONY:
static-analysis: static-analysis-editorconfig

.PHONY: static-analysis-editorconfig
static-analysis-editorconfig: install-eclint
	$(Q)eclint check $$(git ls-files) || (echo "editorconfig check failed. Please run \`make correct\`" && exit 1)

.PHONY: correct
correct: correct-editorconfig

.PHONY: correct-editorconfig
correct-editorconfig: install-eclint
	$(Q)eclint fix $$(git ls-files)

.PHONY: install-eclint
install-eclint:
	$(Q)(command -v eclint > /dev/null) || \
	((command -v npm > /dev/null) && npm install -g eclint) || \
	((command -v yarn > /dev/null) && yarn global add eclint)
