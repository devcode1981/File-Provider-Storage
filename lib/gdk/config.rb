# frozen_string_literal: true

require 'etc'
require_relative 'config_settings'

module GDK
  class Config < ConfigSettings
    GDK_ROOT = Pathname.new(__dir__).parent.parent
    FILE = File.join(GDK_ROOT, 'gdk.yml')

    settings :repositories do
      string(:gitlab) { 'https://gitlab.com/gitlab-org/gitlab.git' }
      string(:gitlab_shell) { 'https://gitlab.com/gitlab-org/gitlab-shell.git' }
      string(:gitlab_workhorse) { 'https://gitlab.com/gitlab-org/gitlab-workhorse.git' }
      string(:gitaly) { 'https://gitlab.com/gitlab-org/gitaly.git' }
      string(:gitlab_pages) { 'https://gitlab.com/gitlab-org/gitlab-pages.git' }
      string(:gitlab_docs) { 'https://gitlab.com/gitlab-com/gitlab-docs.git' }
      string(:gitlab_elasticsearch_indexer) { 'https://gitlab.com/gitlab-org/gitlab-elasticsearch-indexer.git' }
    end

    array(:git_repositories) do
      # This list in not exhaustive yet, as some git repositories are based on
      # a fake GOPATH inside a projects sub directory
      %w[/ gitlab]
        .map { |d| File.join(gdk_root, d) }
        .select { |d| Dir.exist?(d) }
    end

    path(:gdk_root) { GDK_ROOT }

    settings :gdk do
      bool(:ask_to_restart_after_update) { true }
      bool(:debug) { false }
      settings :experimental do
        bool(:ruby_services) { false }
      end
      bool(:overwrite_changes) { false }
      array(:protected_config_files) { [] }
    end

    path(:repositories_root) { config.gdk_root.join('repositories') }

    string(:local_hostname) { '127.0.0.1' }

    string :hostname do
      next "#{config.auto_devops.gitlab.port}.qa-tunnel.gitlab.info" if config.auto_devops.enabled

      read!('hostname') || read!('host') || config.local_hostname
    end

    integer :port do
      next 443 if config.auto_devops.enabled

      read!('port') || 3000
    end

    settings :https do
      bool :enabled do
        next true if config.auto_devops.enabled

        read!('https_enabled') || false
      end
    end

    string :relative_url_root do
      read!('relative_url_root') || '/'
    end

    anything :__uri do
      scheme = config.https? ? 'https' : 'http'

      URI::Generic.build(scheme: scheme, host: config.hostname, port: config.port, path: config.relative_url_root)
    end

    string(:username) { Etc.getpwuid.name }

    settings :webpack do
      string :host do
        next '0.0.0.0' if config.auto_devops.enabled

        read!('webpack_host') || config.hostname
      end
      bool(:static) { false }
      bool(:vendor_dll) { false }

      integer(:port) { read!('webpack_port') || 3808 }
    end

    settings :workhorse do
      integer(:configured_port) { 3333 }

      string :__active_host do
        if config.auto_devops? || config.nginx?
          '0.0.0.0'
        else
          # Workhorse is the user-facing entry point whenever neither nginx nor
          # AutoDevOps is used, so in that situation use the configured GDK hostname.
          config.hostname
        end
      end

      integer :__active_port do
        if config.auto_devops? || config.nginx?
          config.workhorse.configured_port
        else
          # Workhorse is the user-facing entry point whenever neither nginx nor
          # AutoDevOps is used, so in that situation use the configured GDK port.
          config.port
        end
      end

      bool(:auto_update) { true }
    end

    settings :gitlab_shell do
      bool(:auto_update) { true }
      string(:dir) { config.gdk_root.join('gitlab-shell') }
    end

    settings :gitlab_elasticsearch_indexer do
      bool(:auto_update) { true }
    end

    settings :registry do
      bool :enabled do
        next true if config.auto_devops.enabled

        read!('registry_enabled') || false
      end

      string :host do
        next "#{config.auto_devops.registry.port}.qa-tunnel.gitlab.info" if config.auto_devops.enabled

        config.hostname
      end

      string :api_host do
        next "#{config.auto_devops.registry.port}.qa-tunnel.gitlab.info" if config.auto_devops.enabled

        config.hostname
      end

      string :tunnel_host do
        next "#{config.auto_devops.registry.port}.qa-tunnel.gitlab.info" if config.auto_devops.enabled

        config.hostname
      end

      integer(:tunnel_port) { 5000 }

      integer :port do
        read!('registry_port') || 5000
      end

      string :image do
        read!('registry_image') ||
          'registry.gitlab.com/gitlab-org/build/cng/gitlab-container-registry:'\
        'v2.9.1-gitlab'
      end

      integer :external_port do
        next 443 if config.auto_devops.enabled

        5000
      end

      bool(:self_signed) { false }
      bool(:auth_enabled) { true }
    end

    settings :object_store do
      bool(:enabled) { read!('object_store_enabled') || false }
      string(:host) { config.local_hostname }
      integer(:port) { read!('object_store_port') || 9000 }
    end

    settings :gitlab_pages do
      bool(:enabled) { true }
      integer(:port) { read!('gitlab_pages_port') || 3010 }
      bool(:auto_update) { true }
    end

    settings :auto_devops do
      bool(:enabled) { read!('auto_devops_enabled') || false }
      settings :gitlab do
        integer(:port) { read_or_write!('auto_devops_gitlab_port', rand(20000..24999)) }
      end
      settings :registry do
        integer(:port) { read!('auto_devops_registry_port') || (config.auto_devops.gitlab.port + 5000) }
      end
    end

    settings :omniauth do
      settings :google_oauth2 do
        string(:enabled) { !!read!('google_oauth_client_secret') || '' }
        string(:client_id) { read!('google_oauth_client_id') || '' }
        string(:client_secret) { read!('google_oauth_client_secret') || '' }
      end
    end

    settings :geo do
      bool(:enabled) { false }
      string(:node_name) { config.gdk_root.basename.to_s }
      settings :registry_replication do
        bool(:enabled) { false }
        string(:primary_api_url) { 'http://localhost:5000' }
      end
    end

    settings :elasticsearch do
      bool(:enabled) { false }
      string(:version) { '6.5.1' }
      string(:checksum) { '5903e1913a7c96aad96a8227517c40490825f672' }
    end

    settings :tracer do
      string(:build_tags) { 'tracer_static tracer_static_jaeger' }
      settings :jaeger do
        bool(:enabled) { true }
        string(:version) { '1.10.1' }
      end
    end

    settings :nginx do
      bool(:enabled) { false }
      string(:listen) { config.hostname }
      string(:bin) { find_executable!('nginx') || '/usr/sbin/nginx' }
      settings :ssl do
        string(:certificate) { 'localhost.crt' }
        string(:key) { 'localhost.key' }
      end
      settings :http do
        bool(:enabled) { false }
        integer(:port) { 8080 }
      end
      settings :http2 do
        bool(:enabled) { false }
      end
    end

    settings :postgresql do
      integer(:port) { read!('postgresql_port') || 5432 }
      path(:bin_dir) { cmd!(%w[support/pg_bindir]) }
      path(:bin) { config.postgresql.bin_dir.join('postgres') }
      string(:replication_user) { 'gitlab_replication' }
      path(:dir) { config.gdk_root.join('postgresql') }
      path(:data_dir) { config.postgresql.dir.join('data') }
      path(:replica_dir) { config.gdk_root.join('postgresql-replica') }
      settings :replica do
        bool(:enabled) { false }
      end
      settings :geo do
        integer(:port) { read!('postgresql_geo_port') || 5432 }
        path(:dir) { config.gdk_root.join('postgresql-geo') }
      end
    end

    settings :gitaly do
      path(:address) { config.gdk_root.join('gitaly.socket') }
      path(:assembly_dir) { config.gdk_root.join('gitaly', 'assembly') }
      path(:config_file) { config.gdk_root.join('gitaly', 'gitaly.config.toml') }
      path(:internal_socket_dir) { config.gdk_root.join('tmp', 'gitaly') }
      path(:log_dir) { config.gdk_root.join('log', 'gitaly') }
      bool(:auto_update) { true }
    end

    settings :praefect do
      path(:address) { config.gdk_root.join('praefect.socket') }
      path(:config_file) { config.gdk_root.join("gitaly", "praefect.config.toml") }
      bool(:enabled) { true }
      path(:internal_socket_dir) { config.gdk_root.join('tmp', 'praefect') }
      settings :database do
        path(:host) { config.postgresql.dir }
        string(:dbname) { 'praefect_development' }
        string(:sslmode) { 'disable' }
      end
      integer(:node_count) { 1 }
      array(:nodes) do
        settings_array!(config.praefect.node_count) do |i|
          path(:address) { config.gdk_root.join("gitaly-praefect-#{i}.socket") }
          string(:config_file) { "gitaly/gitaly-#{i}.praefect.toml" }
          path(:log_dir) { config.gdk_root.join("log", "praefect-gitaly-#{i}") }
          bool(:primary) { i.zero? }
          string(:service_name) { "praefect-gitaly-#{i}" }
          string(:storage) { "praefect-internal-#{i}" }
          path(:storage_dir) { i.zero? ? config.repositories_root : File.join(config.repositories_root, storage) }
          path(:internal_socket_dir) { config.gdk_root.join('tmp', 'praefect', "gitaly-#{i}") }
        end
      end
    end

    settings :sshd do
      bool(:enabled) { false }
      path(:bin) { find_executable!('sshd') || '/usr/sbin/sshd' }
      string(:listen_address) { config.hostname }
      integer(:listen_port) { 2222 }
      string(:user) { config.username }
      path(:authorized_keys_file) { config.gdk_root.join('.ssh', 'authorized_keys') }
      path(:host_key) { config.gdk_root.join('openssh', 'ssh_host_rsa_key') }
      string(:additional_config) { '' }
    end

    settings :git do
      path(:bin) { find_executable!('git') }
    end

    settings :runner do
      path(:config_file) { config.gdk_root.join('gitlab-runner-config.toml') }
      bool(:enabled) { !!read!(config.runner.config_file) }
      array(:extra_hosts) { [] }
      string(:token) { 'DEFAULT TOKEN: Register your runner to get a valid token' }
    end

    settings :influxdb do
      bool(:enabled) { false }
    end

    settings :grafana do
      bool(:enabled) { false }
    end

    settings :prometheus do
      bool(:enabled) { false }
    end

    settings :openldap do
      bool(:enabled) { false }
    end

    settings :mattermost do
      bool(:enabled) { false }
      integer(:port) { config.auto_devops.gitlab.port + 7000 }
      string(:image) { 'mattermost/mattermost-preview' }
      integer(:local_port) { 8065 }
    end

    settings :gitlab do
      path(:dir) { config.gdk_root.join('gitlab') }
    end
  end
end
