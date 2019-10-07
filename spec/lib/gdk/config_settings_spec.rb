require 'spec_helper'

describe GDK::ConfigSettings do
  class TestConfigSettings < GDK::ConfigSettings
    FILE = 'tmp/foo.yml'

    bar false
  end

  subject(:config) { TestConfigSettings.new }

  describe 'dynamic setting' do
    it 'can read a setting' do
      expect(config.bar).to eq(false)
    end

    context 'with foo.yml' do
      before do
        File.write(temp_path.join('foo.yml'), { 'bar' => 'baz' }.to_yaml)
      end

      after do
        File.unlink(temp_path.join('foo.yml'))
      end

      it 'reads settings from yaml' do
        expect(config.bar).to eq('baz')
      end
    end
  end
end
