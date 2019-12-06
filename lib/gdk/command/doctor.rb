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

        if diagnostic_results.empty?
          show_healthy
        else
          show_results
        end
      end

      def diagnostic_results
        @diagnostic_results ||= diagnostics.each_with_object([]) do |diagnostic, results|
          diagnostic.diagnose
          results << diagnostic.message unless diagnostic.success?
        end
      end

      def diagnostics
        GDK::Diagnostic.all
      end

      private

      attr_reader :stdout, :stderr

      def gdk_start
        Shellout.new('gdk start').run
      end

      def show_healthy
        stdout.puts 'GDK is healthy.'
      end

      def show_results
        stdout.puts warning
        diagnostic_results.each do |result|
          stdout.puts result
        end
      end

      def warning
        <<~WARNING
          #{'=' * 80}
          Please note that these warnings are only used to help in debugging if you
          encounter issues with GDK. If this GDK is working fine for you, you can
          safely ignore them. Thanks!
          #{'=' * 80}

        WARNING
      end
    end
  end
end
