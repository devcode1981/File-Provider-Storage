# frozen_string_literal: true

require 'stringio'

module GDK
  module Diagnostic
    class Configuration < Base
      TITLE = 'GDK Configuration'

      def diagnose
        out = StringIO.new
        err = StringIO.new

        GDK::Command::DiffConfig.new.run(stdout: out, stderr: err)

        out.close
        err.close

        @config_diff = out.string.chomp
      end

      def success?
        @config_diff.empty?
      end

      def detail
        <<~MESSAGE
          Please review the following diff or consider `gdk reconfigure`.

          #{@config_diff}
        MESSAGE
      end
    end
  end
end
