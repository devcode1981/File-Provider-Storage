# frozen_string_literal: true

require 'yaml'

module GDK
  class ConfigSettings
    SettingUndefined = Class.new(StandardError)

    attr_reader :parent, :yaml, :key

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
          sub.new(parent: self, yaml: yaml.fetch(name.to_s, {}), key: [key, name].compact.join('.'))
        end
      else
        raise SettingUndefined, "Could not find the setting '#{name}'"
      end
    end

    def initialize(parent: nil, yaml: nil, key: nil)
      @parent = parent
      @key = key
      @yaml = yaml || load_yaml!
    end

    def dump!(file = nil)
      base_methods = ConfigSettings.new.methods

      yaml = (methods - base_methods).sort.inject({}) do |hash, method|
        value = public_send(method)
        if value.is_a?(ConfigSettings)
          hash[method.to_s] = value.dump!
        else
          hash[method.to_s] = value
        end
        hash
      end

      file.puts(yaml.to_yaml) if file

      yaml
    end

    def dump_run_env!
      <<~RUN_ENV
        export host=#{hostname}
        export port=#{port}
        export relative_url_root=#{relative_url_root}
      RUN_ENV
    end

    def env!(name)
      value = ENV[name]
      value&.empty? ? nil : value
    end

    def cmd!(cmd)
      # Passing an array to IO.popen guards against sh -c.
      # https://gitlab.com/gitlab-org/gitlab-ce/blob/master/doc/development/shell_commands.md#bypass-the-shell-by-splitting-commands-into-separate-tokens
      raise 'command must be an array' unless cmd.is_a?(Array)

      IO.popen(cmd, &:read).chomp
    end

    def find_executable!(bin)
      result = cmd!(%W[which #{bin}])
      result.empty? ? nil : result
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

    def root
      parent&.root || self
    end
    alias_method :config, :root

    def inspect
      "#<GDK::ConfigSettings key:#{key}>"
    end

    # Provide a shorter form for `config.setting.enabled` as `config.setting?`
    def method_missing(method_name, *args, &blk)
      enabled = enabled_value(method_name)

      return super if enabled.nil?

      enabled
    end

    def respond_to_missing?(method_name, include_private = false)
      !enabled_value(method_name).nil? || super
    end

    private

    def enabled_value(method_name)
      chopped_name = method_name.to_s.chop.to_sym

      return public_send(chopped_name).enabled if method_name.to_s.end_with?('?') &&
                                                  respond_to?(chopped_name) &&
                                                  public_send(chopped_name).respond_to?(:enabled)
      nil
    end

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
