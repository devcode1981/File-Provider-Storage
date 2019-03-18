# frozen_string_literal: true

require_relative 'config_file'

module GDK
  class Defaults < ConfigFile
    FILE = 'gdk-defaults.yml'

    def initialize
      super(FILE)
    end

    def respond_to_missing?(method_name, *_args)
      config.respond_to?(method_name) || super
    end

    def method_missing(method_name, *_args, &_block)
      return config[method_name] if data.respond_to?(method_name)

      super
    end
  end
end
