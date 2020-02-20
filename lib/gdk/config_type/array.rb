# frozen_string_literal: true

require_relative 'base'

module GDK
  module ConfigType
    class Array < Base
      def dump!
        value.map(&:dump!)
      end

      def parse
        value.is_a?(::Array)
      end
    end
  end
end
