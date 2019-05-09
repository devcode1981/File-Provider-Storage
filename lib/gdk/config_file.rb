# frozen_string_literal: true

require 'yaml'
require 'erb'
require 'ostruct'

module GDK
  class ConfigFile
    attr_reader :config

    def initialize(file)
      load! File.read(file)

      # Run in a loop for variables that refer other variables
      # See https://stackoverflow.com/a/7235513/89376
      while /<%=.*%>/.match(data)
        load! ERB.new(data).result(config_binding)
      end
    end

    # Inspired by https://stackoverflow.com/a/34501230/89376
    def config_binding
      binding.tap do |b|
        b.local_variable_set(:config, config)
      end
    end

    def cmd!(cmd)
      `#{cmd}`.chomp
    end

    def read!(filename)
      File.read(filename).chomp
    rescue Errno::ENOENT
      nil
    end

    def read_or_write!(filename, value)
      File.read(filename).chomp
    rescue Errno::ENOENT
      File.write(filename, value)
      value
    end

    private

    attr_reader :data

    def load!(data)
      @data = data
      @config = hashes2ostruct(YAML.safe_load(@data))
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
