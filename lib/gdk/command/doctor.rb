# frozen_string_literal: true

module GDK
  module Command
    class Doctor
      def initialize(diagnostics: GDK::Diagnostic.all, stdout: $stdout, stderr: $stderr)
        @diagnostics = diagnostics
        @stdout = stdout
        @stderr = stderr
      end

      def run
        start_necessary_services

        if diagnostic_results.empty?
          show_healthy
        else
          show_results
        end
      end

      private

      attr_reader :diagnostics, :stdout, :stderr

      def diagnostic_results
        @diagnostic_results ||= diagnostics.each_with_object([]) do |diagnostic, results|
          diagnostic.diagnose
          results << diagnostic.message unless diagnostic.success?
        end
      end

      def start_necessary_services
        Shellout.new('gdk start postgresql').run
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
          Please note these warning only exist for debugging purposes and can
          help you when you encounter issues with GDK.
          If your GDK is working fine, you can safely ignore them. Thanks!
          #{'=' * 80}

        WARNING
      end
    end
  end
end
