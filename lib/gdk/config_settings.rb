# frozen_string_literal: true

require 'yaml'

module GDK
  class ConfigSettings
    SettingUndefined = Class.new(StandardError)

    attr_accessor :parent, :yaml

    def self.method_missing(name, *args, &blk)
      if !args.empty?
        define_method(name) do
          yaml.fetch(name.to_s, args.first)
        end
      elsif block_given?
        define_method(name) do
          # return the result of the block if it didn't take an argument
          # otherwise return an instance of the sub ConfigSettings
          return yaml.fetch(name.to_s, instance_eval(&blk)) if blk.arity.zero?

          sub = Class.new(ConfigSettings)
          blk.call(sub)
          sub.new(parent: self, yaml: yaml.fetch(name.to_s, {}))
        end
      else
        raise SettingUndefined, "Could not find the setting '#{name}'"
      end
    end

    # Provide a shorter form for `config.setting.enabled` as `config.setting?`
    def method_missing(name, *args, &blk)
      return super unless name.to_s.end_with?('?')
      setting = name.to_s.chop.to_sym

      return super unless respond_to?(setting) && public_send(setting).respond_to?(:enabled)

      public_send(setting).enabled
    end

    def cmd!(cmd)
      `#{cmd}`.chomp
    end

    def read!(filename)
      sanitized_read!(filename)
    rescue Errno::ENOENT
      nil
    end

    def read_or_write!(filename, value)
      sanitized_read!(filename)
    rescue Errno::ENOENT
      File.write(filename, value)
      value
    end

    def initialize(parent: nil, yaml: nil)
      @parent = parent
      @yaml = yaml || load_yaml!
    end

    def root
      parent&.root || self
    end
    alias_method :config, :root

    private

    def load_yaml!
      return {} unless defined?(self.class::FILE) && File.exist?(self.class::FILE)

      @yaml = YAML.load_file(self.class::FILE) || {}
    end

    def from_yaml(key, default: nil)
      yaml.has_key?(key) ? yaml[key] : default
    end

    def sanitized_read!(filename)
      value = File.read(filename).chomp

      return true if value == "true"
      return false if value == "false"
      return value.to_i if value == value.to_i.to_s
      value
    end
  end
end
