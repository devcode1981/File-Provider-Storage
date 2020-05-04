# frozen_string_literal: true

module GDK
  module Diagnostic
    class Re2 < Base
      TITLE = 're2'
      SCRIPT = "require 're2'; regexp = RE2::Regexp.new('{', log_errors: false); regexp.error unless regexp.ok?"

      def diagnose
        # When re2 and libre2 are out of sync, a seg fault can occur due
        # to some memory corruption (https://github.com/mudge/re2/issues/43).
        # This test doesn't always fail the first time, so repeat the test
        # several times to be sure.
        5.times do
          @command = new_command
          @command.try_run

          break unless @command.success?
        end
      end

      def success?
        @command.success? && @command.read_stdout.empty? && @command.read_stderr.empty?
      end

      def detail
        <<~MESSAGE
          It looks like your system re2 library may have been upgraded, and
          the re2 gem needs to be rebuilt as a result.

          Please run `gem pristine re2`.
        MESSAGE
      end

      private

      def new_command
        Shellout.new(['ruby', '-e', SCRIPT])
      end
    end
  end
end
