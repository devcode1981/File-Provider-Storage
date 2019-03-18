# frozen_string_literal: true

require 'yaml'
require 'erb'
require 'ostruct'

module GDK
  class ConfigFile
    attr_reader :config

    def initialize(file)
      load! File.read(file)

      loop do
        load! ERB.new(data.to_yaml).result(config_binding)

        break unless data.to_yaml =~ /<%=.*%>/
      end
    end

    # Inspired by https://stackoverflow.com/a/34501230/89376
    def config_binding
      binding.tap do |b|
        b.local_variable_set(:config, config)
      end
    end

    private

    attr_reader :data

    def load!(data)
      @data = YAML.safe_load(data)
      @config = hashes2ostruct(@data)
    end

    # From: https://www.dribin.org/dave/blog/archives/2006/11/17/hashes_to_ostruct/
    def hashes2ostruct(object)
      case object
      when Hash
        object = object.clone
        object.each do |key, value|
          object[key] = hashes2ostruct(value)
        end
        OpenStruct.new(object)
      when Array
        object = object.clone
        object.map! { |i| hashes2ostruct(i) }
      else
        object
      end
    end
  end
end
