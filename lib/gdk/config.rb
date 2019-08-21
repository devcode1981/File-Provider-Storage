# frozen_string_literal: true

require 'etc'
require_relative 'config_settings'

module GDK
  class Config < ConfigSettings
    FILE = 'gdk.yml'

    repositories do |r|
      r.gitlab 'https://gitlab.com/gitlab-org/gitlab-ce.git'
      r.gitlab_shell 'https://gitlab.com/gitlab-org/gitlab-shell.git'
      r.gitlab_workhorse 'https://gitlab.com/gitlab-org/gitlab-workhorse.git'
      r.gitaly 'https://gitlab.com/gitlab-org/gitaly.git'
      r.gitaly_proto 'https://gitlab.com/gitlab-org/gitaly-proto.git'
      r.gitlab_pages 'https://gitlab.com/gitlab-org/gitlab-pages.git'
      r.gitlab_docs 'https://gitlab.com/gitlab-com/gitlab-docs.git'
    end

    gdk_root { Dir.pwd }

    repositories_root { File.join(config.gdk_root, 'repositories') }

    hostname do
      next "#{config.auto_devops.gitlab.port}.qa-tunnel.gitlab.info" if config.auto_devops.enabled
      env!('host') || read!('hostname') || read!('host') || 'localhost'
    end

    port do
      next 443 if config.auto_devops.enabled
      env!('port') || read!('port') || 3000
    end

    https do |h|
      h.enabled do
        next true if config.auto_devops.enabled
        read!('https_enabled') || false
      end
    end

    protocol { config.https? ? 'https' : 'http' }

    relative_url_root do
      env!('relative_url_root') || read!('relative_url_root') || '/'
    end

    username { Etc.getlogin }

    webpack do |w|
      w.port { read!('webpack_port') || 3808 }
    end

    registry do |r|
      r.enabled do
        next true if config.auto_devops.enabled
        read!('registry_enabled') || false
      end

      r.host do
        next "#{config.auto_devops.registry.port}.qa-tunnel.gitlab.info" if config.auto_devops.enabled
        '127.0.0.1'
      end

      r.port do
        read!('registry_port') || 5000
      end

      r.external_port do
        next 443 if config.auto_devops.enabled
        5000
      end
    end

    object_store do |o|
      o.enabled { read!('object_store_enabled') || false }
      o.port { read!('object_store_port') || 9000 }
    end

    gitlab_pages do |p|
      p.enabled true
      p.port { read!('gitlab_pages_port') || 3010 }
    end

    auto_devops do |a|
      a.enabled { read!('auto_devops_enabled') || false }
      a.gitlab do |g|
        g.port { read_or_write!('auto_devops_gitlab_port', rand(20000..24999)) }
      end
      a.registry do |r|
        r.port { read!('auto_devops_registry_port') || (config.auto_devops.gitlab.port + 5000) }
      end
    end

    omniauth do |o|
      o.google_oauth2 do |g|
        g.enabled { !!read!('google_oauth_client_secret') }
        g.client_id { read!('google_oauth_client_id') }
        g.client_secret { read!('google_oauth_client_secret') }
      end
    end

    geo do |g|
      g.enabled false
    end

    elasticsearch do |e|
      e.version '6.5.1'
      e.checksum '5903e1913a7c96aad96a8227517c40490825f672'
    end

    tracer do |t|
      t.build_tags 'tracer_static tracer_static_jaeger'
      t.jaeger do |j|
        j.enabled true
        j.version '1.10.1'
      end
    end

    nginx do |n|
      n.enabled false
      n.bin { find_executable!('nginx') || '/usr/sbin/nginx' }
      n.workhorse_port 3333
      n.ssl do |s|
        s.certificate 'localhost.crt'
        s.key 'localhost.key'
      end
      n.http do |h|
        h.enabled false
        h.port 80
      end
    end

    postgresql do |p|
      p.bin_dir { cmd!(%w[support/pg_bindir]) }
      p.replication_user 'gitlab_replication'
      p.dir { "#{config.gdk_root}/postgresql" }
      p.data_dir { "#{config.postgresql.dir}/data" }
      p.replica_dir { "#{config.gdk_root}/postgresql-replica" }
      p.geo_dir { "#{config.gdk_root}/postgresql-geo" }
    end

    gitaly do |g|
      g.assembly_dir { "#{config.gdk_root}/gitaly/assembly" }
      g.address do
        File.join(config.gdk_root, 'gitaly.socket')
      end
    end

    praefect do |p|
      p.enabled { read!('praefect_enabled') || false }
      p.config_file { File.join(config.gdk_root, "gitaly", "praefect.config.toml") }
      p.address { File.join(config.gdk_root, 'praefect.socket') }
      p.nodes do
        gitaly_nodes = (ENV["PRAEFECT_GITALY_NODES"] || "3").to_i
        (0..gitaly_nodes-1).map do |i|
          { storage: "praefect-internal-#{i}", address: File.join(config.gdk_root, "gitaly-praefect-#{i}.socket") }
        end
      end
    end

    sshd do |s|
      s.bin { find_executable!('sshd') || '/usr/sbin/sshd' }
    end

    git do |g|
      g.bin { find_executable!('git') }
    end
  end
end
