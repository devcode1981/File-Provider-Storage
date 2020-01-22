require 'spec_helper'

describe GDK::ConfigSettings do
  class TestConfigSettings < GDK::ConfigSettings
    FILE = 'tmp/foo.yml'

    string(:bar) { 'hello' }
  end

  subject(:config) { TestConfigSettings.new }

  describe 'dynamic setting' do
    it 'can read a setting' do
      expect(config.bar).to eq('hello')
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

  describe '#settings_arrary!' do
    it 'creates an array of the desired number of settings' do
      expect(config.settings_array!(3, &proc { nil }).count).to eq(3)
    end

    it 'creates settings with self as parent' do
      expect(config.settings_array!(1, &proc { nil }).first.parent).to eq(config)
    end

    it 'attributes are available through root config' do
      config = Class.new(GDK::ConfigSettings) do
        array(:arrrr) do
          settings_array!(3) do |i|
            string(:buz) { "sub #{i}" }
          end
        end
      end.new

      expect(config.arrrr.last.buz).to eq('sub 2')
    end
  end
end
