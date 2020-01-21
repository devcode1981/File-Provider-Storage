# frozen_string_literal: true

require_relative 'base'
require 'pathname'

module GDK
  module ConfigType
    class Path < Base
      def dump!
        value.to_s
      end

      def parse
        return if value.nil?

        self.value = Pathname.new(value)
      end
    end
  end
end
