# frozen_string_literal: true

module GDK
  module Diagnostic
    class RubyGems < Base
      TITLE = 'Ruby Gems'

      def diagnose
        # no-op
      end

      def success?
        ffi_ok?
      end

      def detail
        return ffi_load_error_message unless ffi_ok?
      end

      private

      def ffi_load_error_message
        return if ffi_ok?

        <<~MESSAGE
        The ffi Ruby gem has issues:

        #{ffi_load_error}

        Try running the following to fix:

        gem pristine ffi
        MESSAGE
      end

      def ffi_ok?
        ffi_load_error.nil?
      end

      def ffi_load_error
        @ffi_load_error ||= begin
          require 'ffi'
          nil
        rescue LoadError => e
          e.message
        end
      end
    end
  end
end
