# frozen_string_literal: true

require_relative 'config_file'
require_relative 'defaults'

module GDK
  class Config < ConfigFile
    FILE = 'gdk.yml'

    def initialize
      super(FILE)
    end

    def defaults
      @defaults ||= Defaults.new
    end

    def respond_to_missing?(method_name, *_args)
      config.respond_to?(method_name) || defaults.respond_to?(method_name) || super
    end

    def method_missing(method_name, *_args, &_block)
      return config[method_name] if config.respond_to?(method_name)
      return defaults.config[method_name] if defaults.respond_to?(method_name)

      super
    end
  end
end
