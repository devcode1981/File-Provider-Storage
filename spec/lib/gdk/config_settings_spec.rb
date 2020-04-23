# frozen_string_literal: true

require 'spec_helper'

describe GDK::ConfigSettings do
  subject(:config) { described_class.new }

  describe '.array' do
    it 'accepts an array' do
      described_class.array(:foo) { %w[a b] }

      expect { config.foo }.not_to raise_error
    end

    it 'fails on non-array value' do
      described_class.array(:foo) { %q(a b) }

      expect { config.foo }.to raise_error(GDK::ConfigType::TypeError)
    end
  end

  describe '.bool' do
    it 'accepts a bool' do
      described_class.bool(:foo) { 'false' }

      expect { config.foo }.not_to raise_error
      expect(config.foo).to be_falsy
    end

    it 'accepts a bool?' do
      described_class.bool(:foo) { 'false' }

      expect { config.foo? }.not_to raise_error
      expect(config.foo?).to be_falsy
    end

    it 'fails on non-bool value' do
      described_class.bool(:foo) { 'hello' }

      expect { config.foo }.to raise_error(GDK::ConfigType::TypeError)
    end
  end

  describe '.integer' do
    it 'accepts an integer' do
      described_class.integer(:foo) { '333' }

      expect { config.foo }.not_to raise_error
      expect(config.foo).to eq(333)
    end

    it 'fails on non-integer value' do
      described_class.integer(:foo) { '33d' }

      expect { config.foo }.to raise_error(GDK::ConfigType::TypeError)
    end
  end

  describe '.path' do
    it 'accepts a valid path' do
      described_class.path(:foo) { '/tmp' }

      expect { config.foo }.not_to raise_error
      expect(config.foo).to be_a(Pathname)
      expect(config.foo.to_s).to eq('/tmp')
    end

    it 'fails on non-path' do
      described_class.path(:foo) { nil }

      expect { config.foo }.to raise_error(GDK::ConfigType::TypeError)
    end
  end

  describe '.string' do
    it 'accepts a string' do
      described_class.string(:foo) { 'howdy' }

      expect { config.foo }.not_to raise_error
      expect(config.foo).to eq('howdy')
    end

    it 'fails on non-string' do
      described_class.string(:foo) { nil }

      expect { config.foo }.to raise_error(GDK::ConfigType::TypeError)
    end
  end

  describe 'dynamic setting' do
    class TestConfigSettings < described_class
      FILE = 'tmp/foo.yml'

      string(:bar) { 'hello' }
    end

    subject(:config) { TestConfigSettings.new }

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

  describe '#settings_array!' do
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

      expect(config.arrrr.map(&:buz)).to eq(['sub 0', 'sub 1', 'sub 2'])
    end
  end
end
