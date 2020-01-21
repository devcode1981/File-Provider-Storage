# frozen_string_literal: true

module GDK
  module ConfigType
    class Base
      TypeError = Class.new(StandardError)

      attr_accessor :value
      attr_reader :slug

      def initialize(value, slug:)
        @value = value
        @slug = slug

        validate!
      end

      def validate!
        return if parse

        raise TypeError, "Value '#{value}' for slug #{slug} is not a valid #{type}"
      end

      def dump!
        value
      end

      def method_missing(method_name, *args, &block)
        return value.send(method_name, *args, &block) if value_respond_to?(method_name)

        super
      end

      def respond_to_missing?(method_name, include_private = false)
        value_respond_to?(method_name) || super
      end

      private

      def type
        self.class.name.split('::').last.downcase
      end

      def value_respond_to?(method_name)
        value.respond_to?(method_name)
      end
    end
  end
end
