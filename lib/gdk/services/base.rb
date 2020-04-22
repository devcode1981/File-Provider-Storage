# frozen_string_literal: true

module GDK
  module Services
    # @abstract Base class to be used by individual service classes.
    #
    class Base
      # Name of the service
      #
      # @abstract to be implemented by the subclass
      # @return [String] name
      def name
        raise NotImplementedError
      end

      # Command to execute the service
      #
      # @abstract to be implemented by the subclass
      # @return [String] command
      def command
        raise NotImplementedError
      end

      # Is service enabled?
      #
      # @return [Boolean] whether is enabled or not
      def enabled?
        false
      end

      private

      def config
        @config ||= GDK::Config.new
      end
    end
  end
end
