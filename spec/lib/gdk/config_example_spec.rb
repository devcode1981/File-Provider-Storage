# frozen_string_literal: true

require 'spec_helper'
require 'gdk/config_example'

describe GDK::ConfigExample do
  subject(:config) { described_class.new }

  describe '#gdk_root' do
    it 'returns the gdk directory in ~git' do
      expect(config.gdk_root.to_s).to eq('/home/git/gdk')
    end
  end

  describe '#username' do
    it 'returns git' do
      expect(config.username).to eq('git')
    end
  end

  describe '#auto_devops' do
    let(:auto_devops) { config.auto_devops }

    it 'returns a stubbed settings object' do
      expect(auto_devops).to be_a(GDK::ConfigExample::Settings)
    end

    describe '#gitlab' do
      let(:gitlab) { auto_devops.gitlab }

      describe '#port' do
        let(:port) { gitlab.port }

        it 'returns the first port in random range' do
          expect(port).to eq(20_000)
        end
      end
    end
  end

  describe '#dump!' do
    it 'does not read any file' do
      expect(File).not_to receive(:read)

      config.dump!
    end
  end
end
