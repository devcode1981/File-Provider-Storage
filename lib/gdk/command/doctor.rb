# frozen_string_literal: true

module GDK
  module Command
    class Doctor
      def initialize(stdout: $stdout, stderr: $stderr)
        @stdout = stdout
        @stderr = stderr
      end

      def run
        gdk_start

        success = true

        diagnostics.each do |diagnostic|
          diagnostic.diagnose

          next if diagnostic.success?

          show_warning unless warned

          stdout.puts diagnostic.message

          success = false
        end

        return unless success

        stdout.puts 'GDK is ready.'
      end

      def diagnostics
        GDK::Diagnostic.all
      end

      private

      attr_reader :warned, :stdout, :stderr

      def gdk_start
        Shellout.new('gdk start').run
      end

      def show_warning
        stdout.puts warning
        @warned = true
      end

      def warning
        <<~WARNING
        Please note that these warnings are only used to help
        in debugging if you encounter issues with GDK.
        If GDK is working fine for you, you can safely ignore this. Thanks!

        WARNING
      end
    end
  end
end

