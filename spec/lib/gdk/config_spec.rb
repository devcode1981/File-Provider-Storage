require 'spec_helper'

describe GDK::Config do
  let(:auto_devops_enabled) { false }
  let(:nginx_enabled) { false }
  let(:yaml) do
    {
      'auto_devops' => { 'enabled' => auto_devops_enabled },
      'nginx' => { 'enabled' => nginx_enabled },
    }
  end

  subject(:config) { described_class.new(yaml: yaml) }

  describe 'workhorse' do
    describe '#__active_host' do
      context 'when AutoDevOps and nginx are not enabled' do
        it 'returns localhost' do
          expect(config.workhorse.__active_host).to eq('localhost')
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
end
