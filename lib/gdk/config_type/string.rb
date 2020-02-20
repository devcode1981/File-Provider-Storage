# frozen_string_literal: true

require_relative 'base'

module GDK
  module ConfigType
    class String < Base
      def parse
        return if value.nil?

        self.value = value.to_s
      end
    end
  end
end
