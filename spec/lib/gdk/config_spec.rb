require 'spec_helper'

describe GDK::Config do
  let(:auto_devops_enabled) { false }
  let(:nginx_enabled) { false }
  let(:protected_config_files) { ['*'] }
  let(:overwrite_changes) { false }
  let(:yaml) do
    {
      'auto_devops' => { 'enabled' => auto_devops_enabled },
      'gdk' => { 'protected_config_files' => protected_config_files, 'overwrite_changes' => overwrite_changes },
      'nginx' => { 'enabled' => nginx_enabled },
      'hostname' => 'gdk.example.com',
    }
  end

  subject(:config) { described_class.new(yaml: yaml) }

  describe 'workhorse' do
    describe '#__active_host' do
      context 'when AutoDevOps and nginx are not enabled' do
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

      context 'when nginx is enabled' do
        let(:nginx_enabled) { true }

        it 'returns 0.0.0.0' do
          expect(config.workhorse.__active_host).to eq('0.0.0.0')
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
      expect {
        expect(config.dump!).to be_a_kind_of(Hash)
      }.not_to raise_error
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
end
