# frozen_string_literal: true

require_relative 'base'

module GDK
  module ConfigType
    class Bool < Base
      def parse
        case value
        when 'true', true, 't', '1', 1
          self.value = true
        when 'false', false, 'f', '0', 0
          self.value = false
        else
          return false
        end

        true
      end
    end
  end
end
