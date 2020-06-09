# frozen_string_literal: true

require_relative 'base'
require_relative '../config_settings'

module GDK
  module ConfigType
    class Array < Base
      attr_reader :arr, :config

      def initialize(arr, config:, slug:, &blk)
        @arr = arr
        @config = config
        @slug = slug
        @value = instance_exec(&blk)

        validate!
      end

      # Create an array of settings with self as parent
      #
      # @param count [Integer] the number of settings in the array
      def settings_array!(count, &blk)
        Array.new(count) do |i|
          binding.pry
          sub = Class.new(::GDK::ConfigSettings)
          sub.class_exec(&blk)
          sub.new(parent: self, yaml: arr.fetch(i, {}), slug: "#{slug}.#{i}")
        end
      end

      def dump!
        value.map(&:dump!)
      end

      def parse
        value.is_a?(::Array)
      end
    end
  end
end
