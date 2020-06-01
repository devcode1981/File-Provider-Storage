require 'spec_helper'

describe GDK::Config do
  let(:auto_devops_enabled) { false }
  let(:nginx_enabled) { false }
  let(:protected_config_files) { [] }
  let(:overwrite_changes) { false }
  let(:yaml) do
    {
      'auto_devops' => { 'enabled' => auto_devops_enabled },
      'gdk' => { 'protected_config_files' => protected_config_files, 'overwrite_changes' => overwrite_changes },
      'nginx' => { 'enabled' => nginx_enabled },
      'hostname' => 'gdk.example.com'
    }
  end

  subject(:config) { described_class.new(yaml: yaml) }

  before do
    # Ensure a developer's local gdk.yml does not affect tests
    allow_any_instance_of(GDK::ConfigSettings).to receive(:read!).and_return(nil)
  end

  describe 'workhorse' do
    describe '#__active_host' do
      context 'when AutoDevOps is not enabled' do
        it 'returns the configured hostname' do
          expect(config.workhorse.__active_host).to eq(config.hostname)
        end
      end

      context 'when AutoDevOps is enabled' do
        let(:auto_devops_enabled) { true }

        it 'returns 0.0.0.0' do
          expect(config.workhorse.__active_host).to eq('0.0.0.0')
        end
      end
    end
  end

  describe 'container registry' do
    describe 'image' do
      context 'when no image is specified' do
        it 'returns the default image' do
          expect(config.registry.image).to eq('registry.gitlab.com/gitlab-org/build/cng/gitlab-container-registry:v2.9.1-gitlab')
        end
      end
    end
  end

  describe '#__active_port' do
    context 'when AutoDevOps and nginx are not enabled' do
      it 'returns 3000' do
        expect(config.workhorse.__active_port).to eq(3000)
      end
    end

    context 'when AutoDevOps is enabled' do
      let(:auto_devops_enabled) { true }

      it 'returns 3333' do
        expect(config.workhorse.__active_port).to eq(3333)
      end
    end

    context 'when nginx is enabled' do
      let(:nginx_enabled) { true }

      it 'returns 3333' do
        expect(config.workhorse.__active_port).to eq(3333)
      end
    end
  end

  describe '#dump_config!' do
    it 'successfully dumps the config' do
      expect do
        expect(config.dump!).to be_a_kind_of(Hash)
      end.not_to raise_error
    end

    it 'does not dump options intended for internal use only' do
      expect(config).to respond_to(:__uri)
      expect(config.dump!).not_to include('__uri')
    end

    it 'does not dump options based on question mark convenience methods' do
      expect(config.gdk).to respond_to(:debug?)
      expect(config.gdk.dump!).not_to include('debug?')
    end
  end

  describe '#username' do
    before do
      allow(Etc).to receive_message_chain(:getpwuid, :name) { 'iamfoo' }
    end

    it 'returns the short login name of the current process uid' do
      expect(config.username).to eq('iamfoo')
    end
  end

  context 'Geo section' do
    describe 'Registry replication' do
      describe '#enabled' do
        it 'returns false be default' do
          expect(config.geo.registry_replication.enabled).to be false
        end

        context 'when enabled in config file' do
          let(:yaml) do
            {
              'geo' => { 'registry_replication' => { "enabled" => true } }
            }
          end

          it 'returns true' do
            expect(config.geo.registry_replication.enabled).to be true
          end
        end
      end

      describe '#primary_api_url' do
        it 'returns default URL' do
          expect(config.geo.registry_replication.primary_api_url).to eq('http://localhost:5000')
        end

        context 'when URL is specified' do
          let(:yaml) do
            {
              'geo' => { 'registry_replication' => { "primary_api_url" => 'http://localhost:5001' } }
            }
          end

          it 'returns URL from configuration file' do
            expect(config.geo.registry_replication.primary_api_url).to eq('http://localhost:5001')
          end
        end
      end
    end
  end

  describe '#config_file_protected?' do
    subject { config.config_file_protected?('foobar') }

    context 'with full wildcard protected_config_files' do
      let(:protected_config_files) { ['*'] }

      it 'returns true' do
        expect(config.config_file_protected?('foobar')).to eq(true)
      end

      context 'but legacy overwrite_changes set to true' do
        let(:overwrite_changes) { true }

        it 'returns false' do
          expect(config.config_file_protected?('foobar')).to eq(false)
        end
      end
    end
  end

  describe 'runner' do
    before do
      allow_any_instance_of(GDK::ConfigSettings).to receive(:read!).with(config.runner.config_file) { file_contents }
    end

    describe '#extra_hosts' do
      it 'returns []' do
        expect(config.runner.extra_hosts).to eq([])
      end
    end

    context 'when config_file exists' do
      let(:file_contents) do
        <<~CONTENTS
        concurrent = 1
        check_interval = 0

        [session_server]
          session_timeout = 1800

        [[runners]]
          name = "MyRunner"
          url = "http://example.com"
          token = "XXXXXXXXXX"
          executor = "docker"
          [runners.custom_build_dir]
          [runners.docker]
            tls_verify = false
            image = "ruby:2.6"
            privileged = false
            disable_entrypoint_overwrite = false
            oom_kill_disable = false
            disable_cache = false
            volumes = ["/cache"]
            shm_size = 0
          [runners.cache]
            [runners.cache.s3]
            [runners.cache.gcs]
        CONTENTS
      end

      it 'returns true' do
        expect(config.runner.enabled).to be true
      end
    end

    context 'when config_file does not exist' do
      let(:file_contents) { nil }

      it 'returns false' do
        expect(config.runner.enabled).to be false
      end
    end
  end

  describe '#listen_address' do
    it 'returns 127.0.0.1 by default' do
      expect(config.listen_address).to eq('127.0.0.1')
    end
  end

  describe 'gitlab' do
    describe '#dir' do
      it 'returns the GitLab directory' do
        expect(config.gitlab.dir).to eq(Pathname.new('/home/git/gdk/gitlab'))
      end
    end

    describe '#__socket_file' do
      it 'returns the GitLab socket path' do
        expect(config.gitlab.__socket_file).to eq(Pathname.new('/home/git/gdk/gitlab.socket'))
      end
    end

    describe '#__socket_file_escaped' do
      it 'returns the GitLab socket path CGI escaped' do
        expect(config.gitlab.__socket_file_escaped.to_s).to eq('%2Fhome%2Fgit%2Fgdk%2Fgitlab.socket')
      end
    end

    describe 'actioncable' do
      describe '#__socket_file' do
        it 'returns the GitLab ActionCable socket path' do
          expect(config.gitlab.actioncable.__socket_file).to eq(Pathname.new('/home/git/gdk/gitlab.actioncable.socket'))
        end
      end
    end
  end

  describe 'webpack' do
    describe '#vendor_dll' do
      it 'is false by default' do
        expect(config.webpack.vendor_dll).to be false
      end
    end

    describe '#static' do
      it 'is false by default' do
        expect(config.webpack.static).to be false
      end
    end

    describe '#sourcemaps' do
      it 'is true by default' do
        expect(config.webpack.sourcemaps).to be true
      end
    end
  end

  describe 'registry' do
    describe '#external_port' do
      it 'returns 5000' do
        expect(config.registry.external_port).to eq(5000)
      end
    end

    describe '#api_host' do
      context 'when AutoDevOps is not enabled' do
        let(:auto_devops_enabled) { false }

        it 'returns the default hostname' do
          expect(config.registry.api_host).to eq('gdk.example.com')
        end
      end

      context 'when AutoDevOps is enabled' do
        let(:auto_devops_enabled) { true }

        it 'returns the default local hostname' do
          expect(config.registry.api_host).to eq('127.0.0.1')
        end
      end
    end

    describe '#tunnel_host' do
      it 'returns the default hostname' do
        expect(config.registry.tunnel_host).to eq('gdk.example.com')
      end
    end

    describe '#tunnel_port' do
      it 'returns 5000' do
        expect(config.registry.tunnel_port).to eq(5000)
      end
    end
  end

  describe 'object_store' do
    describe '#host' do
      it 'returns the default hostname' do
        expect(config.object_store.host).to eq('127.0.0.1')
      end
    end
  end
end
