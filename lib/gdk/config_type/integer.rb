# frozen_string_literal: true

require_relative 'base'

module GDK
  module ConfigType
    class Integer < Base
      def parse
        orig_value = value
        self.value = value.to_i

        value.to_s == orig_value.to_s
      end
    end
  end
end
