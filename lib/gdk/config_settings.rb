# frozen_string_literal: true

require 'yaml'
require_relative 'config_type/anything'
require_relative 'config_type/array'
require_relative 'config_type/bool'
require_relative 'config_type/integer'
require_relative 'config_type/path'
require_relative 'config_type/string'

module GDK
  class ConfigSettings
    SettingUndefined = Class.new(StandardError)

    attr_reader :parent, :yaml, :slug

    class << self
      def anything(name, &blk)
        setting(name, ConfigType::Anything, &blk)
      end

      def array(name, &blk)
        setting(name, ConfigType::Array, &blk)
      end

      def bool(name, &blk)
        setting(name, ConfigType::Bool, &blk)
      end

      def integer(name, &blk)
        setting(name, ConfigType::Integer, &blk)
      end

      def path(name, &blk)
        setting(name, ConfigType::Path, &blk)
      end

      def string(name, &blk)
        setting(name, ConfigType::String, &blk)
      end

      def settings(name, &blk)
        define_method(name) do
          subconfig!(name, &blk)
        end
      end

      private

      def setting(name, config_type, &blk)
        define_method(name) do
          config_type.new(yaml.fetch(name.to_s, instance_eval(&blk)), slug: slug_for(name)).value
        end
      end
    end

    def initialize(parent: nil, yaml: nil, slug: nil)
      @parent = parent
      @slug = slug
      @yaml = yaml || load_yaml!
    end

    def dump!(file = nil)
      base_methods = ConfigSettings.new.methods

      yaml = (methods - base_methods).sort.inject({}) do |hash, method|
        # If a config starts with a double underscore,
        # it's an internal config so don't dump it out
        next hash if method.to_s.start_with?('__')

        value = fetch(method)
        if value.is_a?(ConfigSettings)
          hash[method.to_s] = value.dump!
        elsif value.is_a?(Enumerable) && value.first.is_a?(ConfigSettings)
          hash[method.to_s] = value.map(&:dump!)
        elsif value.is_a?(Pathname)
          hash[method.to_s] = value.to_s
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
        export GITLAB_TRACING='opentracing://jaeger?http_endpoint=http%3A%2F%2Flocalhost%3A14268%2Fapi%2Ftraces&sampler=const&sampler_param=1'
        export GITLAB_TRACING_URL='http://localhost:16686/search?service={{ service }}&tags=%7B"correlation_id"%3A"{{ correlation_id }}"%7D'
      RUN_ENV
    end

    def cmd!(cmd)
      # Passing an array to IO.popen guards against sh -c.
      # https://gitlab.com/gitlab-org/gitlab/blob/master/doc/development/shell_commands.md#bypass-the-shell-by-splitting-commands-into-separate-tokens
      raise ::ArgumentError.new('Command must be an array') unless cmd.is_a?(Array)

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

    # Create an array of settings with self as parent
    #
    # @param count [Integer] the number of settings in the array
    def settings_array!(count, &blk)
      count.times.map do |i|
        subconfig!(i) do
          instance_exec(i, &blk)
        end
      end
    end

    def fetch(slug, *args)
      raise ::ArgumentError.new(%Q[Wrong number of arguments (#{args.count + 1} for 1..2)]) if args.count > 1

      return public_send(slug) if respond_to?(slug)

      raise SettingUndefined.new(%Q[Could not fetch the setting '#{slug}' in '#{self.slug || '<root>'}']) if args.empty?

      args.first
    end

    def [](slug)
      fetch(slug, nil)
    end

    def dig(*slugs)
      slugs = slugs.first.to_s.split('.') if slugs.one?

      value = fetch(slugs.shift)

      return value if slugs.empty?

      value.dig(*slugs)
    end

    def config_file_protected?(target)
      return false if gdk.overwrite_changes

      gdk.protected_config_files&.any? { |pattern| File.fnmatch(pattern, target) }
    end

    def root
      parent&.root || self
    end
    alias_method :config, :root

    def inspect
      "#<GDK::ConfigSettings slug:#{slug}>"
    end

    def to_s
      dump!.to_yaml
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

    def slug_for(name)
      [slug, name].compact.join('.')
    end

    def enabled_value(method_name)
      return nil unless method_name.to_s.end_with?('?')

      chopped_name = method_name.to_s.chop.to_sym
      fetch(chopped_name, nil)&.fetch(:enabled, nil)
    end

    def subconfig!(name, &blk)
      sub = Class.new(ConfigSettings)
      sub.class_eval(&blk)
      sub.new(parent: self, yaml: yaml.fetch(name.to_s, {}), slug: slug_for(name))
    end

    def load_yaml!
      return {} unless defined?(self.class::FILE) && File.exist?(self.class::FILE)

      YAML.load_file(self.class::FILE) || {}
    end

    def from_yaml(slug, default: nil)
      yaml.has_slug?(slug) ? yaml[slug] : default
    end

    def sanitized_read!(filename)
      File.read(filename).chomp
    end
  end
end
