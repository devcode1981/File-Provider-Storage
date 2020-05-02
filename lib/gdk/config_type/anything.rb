# frozen_string_literal: true

require_relative 'base'

module GDK
  module ConfigType
    class Anything < Base
      def parse
        true
      end
    end
  end
end
